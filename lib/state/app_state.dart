import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/avatar_library.dart';
import '../data/mock_data.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/backend.dart';

/// Holds local UI state + an in-memory cache of conversations and messages.
///
/// Two operating modes:
///   - **Mock mode** ([backend] is null) — bootstraps from `MockData` and
///     mutations stay local. Used for the no-backend demo.
///   - **Live mode** ([backend] is non-null) — bootstrap pulls real
///     conversations from Supabase, subscribes to live message inserts, and
///     every mutation does an optimistic local update + a fire-and-forget
///     write through [backend].
///
/// Screens read from this cache synchronously; they don't need to know which
/// mode is active.
class AppState extends ChangeNotifier {
  AppState({Backend? backend}) : _backend = backend;

  final Backend? _backend;

  // ── Launch state ──────────────────────────────────────────────────────────
  bool didSplash = true;
  bool didWelcome = true;
  bool ready = false; // true once the initial fetch completes
  bool needsOnboarding = false;

  // ── Prefs (UI only) ───────────────────────────────────────────────────────
  bool darkMode = false;
  bool notifications = true;
  bool doNotDisturb = false;
  bool readReceipts = true;

  // ── Identity ──────────────────────────────────────────────────────────────
  late AppUser me;
  String workingOn = 'figuring it out';

  // ── Data ──────────────────────────────────────────────────────────────────
  late List<AppUser> users;
  late List<Conversation> conversations;

  final Map<String, AvatarSpec> avatarLookup = {};

  AppUser pulse = AppUser(
    id: 'ai_pulse',
    name: 'Pulse',
    avatarId: 'ai:pulse',
    presence: Presence.online,
    status: 'your quiet helper',
    isAi: true,
  );

  // ── Live mode bookkeeping ────────────────────────────────────────────────
  StreamSubscription<Message>? _messagesSub;
  Timer? _heartbeatTimer;

  // ── Bootstrap ────────────────────────────────────────────────────────────
  Future<void> bootstrap() async {
    // Always register Pulse's avatar.
    avatarLookup['ai:pulse'] = AvatarLibrary.custom(
      id: 'ai:pulse',
      initials: 'P',
      tone: PaperTone.ink,
    );

    if (_backend != null && _backend.currentUser != null) {
      await _bootstrapFromBackend();
    } else {
      _bootstrapFromMock();
    }
    ready = true;
    notifyListeners();
  }

  /// Manual re-fetch used by pull-to-refresh + workspace-switch.
  Future<void> refresh() async {
    if (_backend == null || _backend.currentUser == null) return;
    await _bootstrapFromBackend();
    notifyListeners();
  }

  void _bootstrapFromMock() {
    final seeded = MockData.build(pulse: pulse);
    me = seeded.me;
    users = seeded.users;
    conversations = seeded.conversations;

    avatarLookup[me.avatarId] =
        AvatarLibrary.forUser(userId: me.id, name: me.name);
    for (final u in users) {
      avatarLookup[u.avatarId] =
          AvatarLibrary.forUser(userId: u.id, name: u.name);
    }
    for (final c in conversations) {
      if (c.isGroup &&
          c.groupAvatarId != null &&
          !avatarLookup.containsKey(c.groupAvatarId!)) {
        avatarLookup[c.groupAvatarId!] = AvatarLibrary.custom(
          id: c.groupAvatarId!,
          initials: AvatarLibrary.initialsFrom(c.groupName ?? '··'),
          tone: AvatarLibrary.toneFor(c.id),
        );
      }
    }
  }

  Future<void> _bootstrapFromBackend() async {
    final b = _backend!;
    me = b.currentUser!;
    avatarLookup[me.avatarId] =
        AvatarLibrary.forUser(userId: me.id, name: me.name);

    // Pull everything in parallel.
    final results = await Future.wait([
      b.listConversations(),
      b.listUsers(),
    ]);
    conversations = results[0] as List<Conversation>;
    users = (results[1] as List<AppUser>)
        .where((u) => u.id != me.id)
        .toList(growable: true);

    for (final u in users) {
      avatarLookup[u.avatarId] =
          AvatarLibrary.forUser(userId: u.id, name: u.name);
    }
    for (final c in conversations) {
      if (c.isGroup && c.groupAvatarId != null) {
        avatarLookup[c.groupAvatarId!] = AvatarLibrary.custom(
          id: c.groupAvatarId!,
          initials: AvatarLibrary.initialsFrom(c.groupName ?? '··'),
          tone: AvatarLibrary.toneFor(c.id),
        );
      }
    }

    needsOnboarding = !(await b.isOnboarded());

    // Live: one subscription that fans new messages into the right convo.
    _messagesSub?.cancel();
    _messagesSub = b.subscribeAllMessages(
      conversationIds: conversations.map((c) => c.id).toList(),
    ).listen(_handleIncomingMessage);

    // Heartbeat keeps presence "online" while the tab is open.
    unawaited(b.heartbeat());
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => unawaited(b.heartbeat()),
    );
  }

  void finishOnboarding() {
    needsOnboarding = false;
    notifyListeners();
    unawaited(_backend?.markOnboarded());
  }

  void _handleIncomingMessage(Message m) {
    final convo = conversations.where((c) => true).firstWhere(
          (c) =>
              c.participantIds.contains(m.authorId) ||
              c.messages.any((existing) => existing.id == m.id),
          orElse: () => Conversation(
            id: '__none__',
            participantIds: const [],
            messages: const [],
          ),
        );
    if (convo.id == '__none__') return;
    if (convo.messages.any((x) => x.id == m.id)) return;
    convo.messages.add(m);
    if (m.authorId != me.id) convo.unread += 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  // ── Prefs ────────────────────────────────────────────────────────────────
  void toggleDarkMode(bool v) {
    darkMode = v;
    notifyListeners();
  }

  void toggleNotifications(bool v) {
    notifications = v;
    notifyListeners();
  }

  void toggleDnd(bool v) {
    doNotDisturb = v;
    notifyListeners();
  }

  void toggleReadReceipts(bool v) {
    readReceipts = v;
    notifyListeners();
  }

  // ── Profile ─────────────────────────────────────────────────────────────
  void updateName(String name) {
    me = me.copyWith(name: name);
    final current = avatarLookup[me.avatarId];
    if (current != null) {
      avatarLookup[me.avatarId] = current.copyWith(
        initials: AvatarLibrary.initialsFrom(name),
      );
    }
    notifyListeners();
    unawaited(_backend?.updateProfile(
      name: name,
      initials: AvatarLibrary.initialsFrom(name),
    ));
  }

  void updateWorkingOn(String value) {
    workingOn = value;
    notifyListeners();
    unawaited(_backend?.updateProfile(status: value));
  }

  void updateMyAvatar({String? initials, PaperTone? tone}) {
    final current = avatarLookup[me.avatarId];
    if (current == null) return;
    avatarLookup[me.avatarId] = current.copyWith(
      initials: initials?.toUpperCase(),
      tone: tone,
    );
    notifyListeners();
    unawaited(_backend?.updateProfile(initials: initials?.toUpperCase()));
  }

  AvatarSpec? specFor(String avatarId) => avatarLookup[avatarId];

  // ── Conversations ────────────────────────────────────────────────────────
  List<Conversation> get directChats =>
      conversations.where((c) => !c.isGroup && !c.archived).toList();

  List<Conversation> get groupChats =>
      conversations.where((c) => c.isGroup && !c.archived).toList();

  AppUser userById(String id) {
    if (id == pulse.id) return pulse;
    if (id == me.id) return me;
    return users.firstWhere(
      (u) => u.id == id,
      orElse: () => pulse,
    );
  }

  void muteConversation(String id) {
    final c = conversations.firstWhere((c) => c.id == id);
    c.muted = !c.muted;
    notifyListeners();
    unawaited(_backend?.setMute(id, c.muted));
  }

  void archiveConversation(String id) {
    final c = conversations.firstWhere((c) => c.id == id);
    c.archived = !c.archived;
    notifyListeners();
    unawaited(_backend?.setArchived(id, c.archived));
  }

  Future<void> sendMessage(String conversationId, String text,
      {String? replyToId}) async {
    final c = conversations.firstWhere((c) => c.id == conversationId);
    final localId = 'm_${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = Message(
      id: localId,
      authorId: me.id,
      text: text,
      sentAt: DateTime.now(),
      read: false,
      replyToId: replyToId,
    );
    c.messages.add(optimistic);
    notifyListeners();

    if (_backend == null) return;
    try {
      final real = await _backend.sendMessage(
        conversationId,
        text,
        replyToId: replyToId,
      );
      // Swap the optimistic placeholder for the real id.
      final idx = c.messages.indexWhere((m) => m.id == localId);
      if (idx >= 0) c.messages[idx] = real;
      notifyListeners();
    } catch (e) {
      // Leave the optimistic message; mark as not-read so it stays visible.
      // ignore: avoid_print
      print('[backend] sendMessage failed: $e');
    }
  }

  void toggleReaction(Message m, Reaction r) {
    if (m.reactions.contains(r)) {
      m.reactions.remove(r);
    } else {
      m.reactions.add(r);
    }
    notifyListeners();
    unawaited(_backend?.toggleReaction(m.id, r));
  }

  void togglePin(Message m) {
    m.pinned = !m.pinned;
    notifyListeners();
    unawaited(_backend?.togglePin(m.id, m.pinned));
  }

  void notifyListenersPublic() => notifyListeners();

  List<Message> pinnedDecisions(String conversationId) {
    final c = conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => conversations.first,
    );
    return c.messages.where((m) => m.pinned).toList();
  }

  Message? messageById(String conversationId, String messageId) {
    final c = conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => conversations.first,
    );
    for (final m in c.messages) {
      if (m.id == messageId) return m;
    }
    return null;
  }

  void markRead(String conversationId) {
    final c = conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => conversations.first,
    );
    c.unread = 0;
    for (final m in c.messages) {
      m.read = true;
    }
    notifyListeners();
    unawaited(_backend?.markRead(conversationId));
  }

  Future<void> renameGroup(String conversationId, String name) async {
    final c = conversations.firstWhere((c) => c.id == conversationId);
    c.groupName = name;
    final avId = c.groupAvatarId;
    if (avId != null) {
      final spec = avatarLookup[avId];
      if (spec != null) {
        avatarLookup[avId] = spec.copyWith(
          initials: AvatarLibrary.initialsFrom(name),
        );
      }
    }
    notifyListeners();
    unawaited(_backend?.renameGroup(conversationId, name));
  }

  Future<void> addGroupMembers(
      String conversationId, List<String> userIds) async {
    final c = conversations.firstWhere((c) => c.id == conversationId);
    for (final id in userIds) {
      if (!c.participantIds.contains(id)) c.participantIds.add(id);
    }
    notifyListeners();
    unawaited(_backend?.addGroupMembers(conversationId, userIds));
  }

  Future<void> removeGroupMember(
      String conversationId, String userId) async {
    final c = conversations.firstWhere((c) => c.id == conversationId);
    c.participantIds.remove(userId);
    notifyListeners();
    unawaited(_backend?.removeGroupMember(conversationId, userId));
  }

  Future<void> leaveGroup(String conversationId) async {
    conversations.removeWhere((c) => c.id == conversationId);
    notifyListeners();
    unawaited(_backend?.leaveGroup(conversationId));
  }

  Future<Conversation> createGroup({
    required String name,
    required List<String> memberIds,
    PaperTone? tone,
  }) async {
    final localId = 'g_${DateTime.now().microsecondsSinceEpoch}';
    final avatarId = 'gav:$localId';
    avatarLookup[avatarId] = AvatarLibrary.custom(
      id: avatarId,
      initials: AvatarLibrary.initialsFrom(name),
      tone: tone ?? AvatarLibrary.toneFor(localId),
    );

    if (_backend != null) {
      try {
        final remote = await _backend.createGroup(
          name: name,
          memberIds: memberIds,
        );
        avatarLookup[remote.groupAvatarId ?? avatarId] = AvatarLibrary.custom(
          id: remote.groupAvatarId ?? avatarId,
          initials: AvatarLibrary.initialsFrom(name),
          tone: tone ?? AvatarLibrary.toneFor(remote.id),
        );
        conversations = [remote, ...conversations];
        notifyListeners();
        return remote;
      } catch (e) {
        // ignore: avoid_print
        print('[backend] createGroup failed: $e');
        rethrow;
      }
    }

    final convo = Conversation(
      id: localId,
      participantIds: [me.id, ...memberIds, pulse.id],
      messages: [
        Message(
          id: 'm_${DateTime.now().microsecondsSinceEpoch}',
          authorId: pulse.id,
          text: 'You started "$name". Say hi.',
          sentAt: DateTime.now(),
          isAi: true,
        ),
      ],
      isGroup: true,
      groupName: name,
      groupAvatarId: avatarId,
    );
    conversations = [convo, ...conversations];
    notifyListeners();
    return convo;
  }

  Future<Conversation> createOneOnOne(String otherUserId) async {
    final existing = conversations.firstWhere(
      (c) =>
          !c.isGroup &&
          c.participantIds.contains(otherUserId) &&
          c.participantIds.contains(me.id),
      orElse: () => Conversation(
        id: '__none__',
        participantIds: const [],
        messages: const [],
      ),
    );
    if (existing.id != '__none__') return existing;

    if (_backend != null) {
      final remote = await _backend.createOneOnOne(otherUserId);
      conversations = [remote, ...conversations];
      notifyListeners();
      return remote;
    }

    final convo = Conversation(
      id: 'd_${DateTime.now().microsecondsSinceEpoch}',
      participantIds: [me.id, otherUserId, pulse.id],
      messages: [],
    );
    conversations = [convo, ...conversations];
    notifyListeners();
    return convo;
  }
}
