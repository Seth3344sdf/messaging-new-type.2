import 'package:flutter/foundation.dart';

import '../data/avatar_library.dart';
import '../data/mock_data.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';

class AppState extends ChangeNotifier {
  // Launch state — both true by default so the app opens straight to the
  // chats list, no splash or promise screen.
  bool didSplash = true;
  bool didWelcome = true;

  // Prefs (UI only)
  bool darkMode = false;
  bool notifications = true;
  bool doNotDisturb = false;
  bool readReceipts = true;

  // Identity
  late AppUser me;
  String workingOn = 'figuring it out';

  // Data
  late List<AppUser> users;
  late List<Conversation> conversations;

  // Avatar registry keyed by avatarId. Every user has one. Groups can have
  // their own (initials derived from the group name).
  final Map<String, AvatarSpec> avatarLookup = {};

  AppUser pulse = AppUser(
    id: 'ai_pulse',
    name: 'Pulse',
    avatarId: 'ai:pulse',
    presence: Presence.online,
    status: 'your quiet helper',
    isAi: true,
  );

  void bootstrap() {
    avatarLookup.clear();

    // Register pulse with an ink-tone "P" so it reads as distinct.
    avatarLookup['ai:pulse'] = AvatarLibrary.custom(
      id: 'ai:pulse',
      initials: 'P',
      tone: PaperTone.ink,
    );

    final seeded = MockData.build(pulse: pulse);
    me = seeded.me;
    users = seeded.users;
    conversations = seeded.conversations;

    // Register every user's avatar from their name + id.
    avatarLookup[me.avatarId] =
        AvatarLibrary.forUser(userId: me.id, name: me.name);
    for (final u in users) {
      avatarLookup[u.avatarId] =
          AvatarLibrary.forUser(userId: u.id, name: u.name);
    }
    // Group avatars seeded by mock data.
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

  void completeSplash() {
    didSplash = true;
    notifyListeners();
  }

  void completeWelcome() {
    didWelcome = true;
    notifyListeners();
  }

  // Prefs
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

  // Profile
  void updateName(String name) {
    me = me.copyWith(name: name);
    // Keep my initials in sync with my name unless they've been manually edited.
    final current = avatarLookup[me.avatarId];
    if (current != null) {
      avatarLookup[me.avatarId] = current.copyWith(
        initials: AvatarLibrary.initialsFrom(name),
      );
    }
    notifyListeners();
  }

  void updateWorkingOn(String value) {
    workingOn = value;
    notifyListeners();
  }

  /// Update the current user's avatar: new initials, new tone, or both.
  void updateMyAvatar({String? initials, PaperTone? tone}) {
    final current = avatarLookup[me.avatarId];
    if (current == null) return;
    avatarLookup[me.avatarId] = current.copyWith(
      initials: initials?.toUpperCase(),
      tone: tone,
    );
    notifyListeners();
  }

  AvatarSpec? specFor(String avatarId) => avatarLookup[avatarId];

  // Conversations
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
  }

  void archiveConversation(String id) {
    final c = conversations.firstWhere((c) => c.id == id);
    c.archived = !c.archived;
    notifyListeners();
  }

  void sendMessage(String conversationId, String text, {String? replyToId}) {
    final c = conversations.firstWhere((c) => c.id == conversationId);
    c.messages.add(Message(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      authorId: me.id,
      text: text,
      sentAt: DateTime.now(),
      read: false,
      replyToId: replyToId,
    ));
    notifyListeners();
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

  void toggleReaction(Message m, Reaction r) {
    if (m.reactions.contains(r)) {
      m.reactions.remove(r);
    } else {
      m.reactions.add(r);
    }
    notifyListeners();
  }

  void togglePin(Message m) {
    m.pinned = !m.pinned;
    notifyListeners();
  }

  void notifyListenersPublic() => notifyListeners();

  List<Message> pinnedDecisions(String conversationId) {
    final c = conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => conversations.first,
    );
    return c.messages.where((m) => m.pinned).toList();
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
  }

  Conversation createGroup({
    required String name,
    required List<String> memberIds,
    PaperTone? tone,
  }) {
    final groupId = 'g_${DateTime.now().microsecondsSinceEpoch}';
    final avatarId = 'gav:$groupId';
    avatarLookup[avatarId] = AvatarLibrary.custom(
      id: avatarId,
      initials: AvatarLibrary.initialsFrom(name),
      tone: tone ?? AvatarLibrary.toneFor(groupId),
    );
    final convo = Conversation(
      id: groupId,
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

  Conversation createOneOnOne(String otherUserId) {
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
