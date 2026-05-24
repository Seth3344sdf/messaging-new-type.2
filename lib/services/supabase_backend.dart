import 'dart:async';

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' hide Presence;

import '../models/conversation.dart';
import '../models/message.dart' as model;
import '../models/user.dart';
import '../models/workspace.dart';
import 'backend.dart';

/// Live backend backed by Supabase: Postgres for data, Realtime for live
/// updates, GoTrue for auth. Schema lives in supabase/migrations/0001_init.sql.
class SupabaseBackend implements Backend {
  SupabaseBackend(this._client);

  final SupabaseClient _client;

  // ── Auth ──────────────────────────────────────────────────────────────────
  @override
  Stream<AppUser?> get authChanges =>
      _client.auth.onAuthStateChange.map((event) => _userFromSession(event.session));

  @override
  AppUser? get currentUser => _userFromSession(_client.auth.currentSession);

  AppUser? _userFromSession(Session? s) {
    if (s == null) return null;
    final u = s.user;
    final meta = u.userMetadata ?? {};
    return AppUser(
      id: u.id,
      name: (meta['name'] as String?) ??
          (u.email != null ? u.email!.split('@').first : 'You'),
      avatarId: 'u:${u.id}',
      presence: Presence.online,
      status: meta['status'] as String?,
    );
  }

  @override
  Future<void> signInWithMagicLink(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      // Web: returns to current host. iOS/macOS: configure a deeplink scheme
      // in Supabase Auth → URL Configuration and supply it here.
      emailRedirectTo: null,
    );
  }

  @override
  Future<void> signInWithApple() async {
    // Requires "Apple" provider to be enabled in Supabase Studio →
    // Authentication → Providers, with the service id, key, team id, etc.
    // See BACKEND.md.
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: null,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  // ── Profiles ──────────────────────────────────────────────────────────────
  @override
  Future<void> updateProfile(
      {String? name, String? status, String? initials}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final payload = <String, dynamic>{
      if (name != null) 'name': name,
      if (status != null) 'status': status,
      if (initials != null) 'initials': initials,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (payload.isEmpty) return;
    await _client.from('profiles').update(payload).eq('id', uid);
  }

  @override
  Future<bool> isOnboarded() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    final row = await _client
        .from('profiles')
        .select('onboarded')
        .eq('id', uid)
        .maybeSingle();
    return (row?['onboarded'] as bool?) ?? false;
  }

  @override
  Future<void> markOnboarded() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('profiles').update({'onboarded': true}).eq('id', uid);
  }

  @override
  Future<List<Workspace>> listWorkspaces() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];
    final memberships = await _client
        .from('workspace_members')
        .select('workspace_id')
        .eq('user_id', uid);
    if (memberships.isEmpty) return const [];
    final ids = [for (final m in memberships) m['workspace_id'] as String];
    final rows = await _client
        .from('workspaces')
        .select('id, name, slug')
        .inFilter('id', ids)
        .order('name');
    return rows
        .map<Workspace>((r) => Workspace(
              id: r['id'] as String,
              name: r['name'] as String,
              slug: r['slug'] as String,
            ))
        .toList();
  }

  @override
  Future<Workspace> createWorkspace(String name) async {
    final uid = _requireUid();
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final inserted = await _client
        .from('workspaces')
        .insert({
          'name': name,
          'slug': '$slug-${DateTime.now().millisecondsSinceEpoch}',
          'created_by': uid,
        })
        .select('id, name, slug')
        .single();
    await _client.from('workspace_members').insert({
      'workspace_id': inserted['id'],
      'user_id': uid,
      'role': 'owner',
    });
    return Workspace(
      id: inserted['id'] as String,
      name: inserted['name'] as String,
      slug: inserted['slug'] as String,
    );
  }

  @override
  Future<void> heartbeat() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client
        .from('profiles')
        .update({'last_seen_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', uid);
  }

  // ── Typing ───────────────────────────────────────────────────────────────
  final Map<String, RealtimeChannel> _typingChannels = {};

  @override
  Future<void> broadcastTyping(String conversationId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final channel = _typingChannels.putIfAbsent(
      conversationId,
      () => _client.channel(
        'typing:$conversationId',
        opts: const RealtimeChannelConfig(self: false),
      )..subscribe(),
    );
    await channel.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': uid, 'at': DateTime.now().millisecondsSinceEpoch},
    );
  }

  @override
  Stream<Set<String>> subscribeTyping(String conversationId) {
    final controller = StreamController<Set<String>>();
    final activity = <String, DateTime>{};
    Set<String> snapshot() => activity.entries
        .where((e) =>
            DateTime.now().difference(e.value) < const Duration(seconds: 4))
        .map((e) => e.key)
        .toSet();
    Timer? pruneTimer;
    void emit() => controller.add(snapshot());
    final channel = _client
        .channel('typing:$conversationId')
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final uid = payload['user_id'] as String?;
            if (uid == null) return;
            if (uid == _client.auth.currentUser?.id) return;
            activity[uid] = DateTime.now();
            emit();
          },
        )
        .subscribe();
    pruneTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => emit(),
    );
    controller.onCancel = () {
      pruneTimer?.cancel();
      _client.removeChannel(channel);
    };
    return controller.stream;
  }

  @override
  Future<List<AppUser>> listUsers() async {
    final rows = await _client
        .from('profiles')
        .select('id, name, status, initials, avatar_tone, last_seen_at')
        .order('name');
    return rows.map<AppUser>((r) {
      final lastSeen = r['last_seen_at'] == null
          ? null
          : DateTime.parse(r['last_seen_at'] as String);
      final presence = _presenceFromLastSeen(lastSeen);
      return AppUser(
        id: r['id'] as String,
        name: r['name'] as String,
        avatarId: 'u:${r['id']}',
        presence: presence,
        status: r['status'] as String?,
      );
    }).toList();
  }

  Presence _presenceFromLastSeen(DateTime? t) {
    if (t == null) return Presence.offline;
    final age = DateTime.now().toUtc().difference(t.toUtc());
    if (age.inMinutes < 2) return Presence.online;
    if (age.inMinutes < 10) return Presence.idle;
    return Presence.offline;
  }

  // ── Conversations ─────────────────────────────────────────────────────────
  @override
  Future<List<Conversation>> listConversations() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];

    // Pull conversation rows where the user is a member.
    final memberships = await _client
        .from('conversation_members')
        .select('conversation_id, muted, archived, last_read_at')
        .eq('user_id', uid);

    if (memberships.isEmpty) return const [];

    final conversationIds = [
      for (final m in memberships) m['conversation_id'] as String
    ];

    final convs = await _client
        .from('conversations')
        .select('id, kind, name, avatar_id, created_by, created_at')
        .inFilter('id', conversationIds);

    final allMembers = await _client
        .from('conversation_members')
        .select('conversation_id, user_id')
        .inFilter('conversation_id', conversationIds);

    // Bucket members per conversation.
    final byConv = <String, List<String>>{};
    for (final m in allMembers) {
      byConv
          .putIfAbsent(m['conversation_id'] as String, () => [])
          .add(m['user_id'] as String);
    }

    // Latest message per conversation for previews.
    final recent = await _client
        .from('messages')
        .select('id, conversation_id, author_id, body, created_at, '
            'reply_to_id, pinned, is_ai')
        .inFilter('conversation_id', conversationIds)
        .order('created_at', ascending: false)
        .limit(50);

    final latestByConv = <String, List<model.Message>>{};
    for (final row in recent) {
      latestByConv
          .putIfAbsent(row['conversation_id'] as String, () => [])
          .add(_messageFromRow(row));
    }

    return [
      for (final c in convs)
        Conversation(
          id: c['id'] as String,
          participantIds: byConv[c['id']] ?? const [],
          messages:
              (latestByConv[c['id']] ?? const []).reversed.toList(growable: true),
          isGroup: (c['kind'] as String) == 'group',
          groupName: c['name'] as String?,
          groupAvatarId: c['avatar_id'] as String?,
        ),
    ];
  }

  @override
  Future<Conversation> createOneOnOne(String otherUserId) async {
    final uid = _requireUid();
    final inserted = await _client
        .from('conversations')
        .insert({'kind': 'direct', 'created_by': uid})
        .select('id, kind, name, avatar_id, created_by, created_at')
        .single();
    final convId = inserted['id'] as String;
    await _client.from('conversation_members').insert([
      {'conversation_id': convId, 'user_id': uid, 'role': 'owner'},
      {'conversation_id': convId, 'user_id': otherUserId, 'role': 'member'},
    ]);
    return Conversation(
      id: convId,
      participantIds: [uid, otherUserId],
      messages: [],
    );
  }

  @override
  Future<Conversation> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    final uid = _requireUid();
    final inserted = await _client
        .from('conversations')
        .insert({
          'kind': 'group',
          'name': name,
          'avatar_id': 'gav:${DateTime.now().millisecondsSinceEpoch}',
          'created_by': uid,
        })
        .select('id, name, avatar_id')
        .single();
    final convId = inserted['id'] as String;
    final memberRows = <Map<String, dynamic>>[
      {'conversation_id': convId, 'user_id': uid, 'role': 'owner'},
      for (final m in memberIds)
        {'conversation_id': convId, 'user_id': m, 'role': 'member'},
    ];
    await _client.from('conversation_members').insert(memberRows);
    return Conversation(
      id: convId,
      participantIds: [uid, ...memberIds],
      messages: [],
      isGroup: true,
      groupName: name,
      groupAvatarId: inserted['avatar_id'] as String?,
    );
  }

  @override
  Future<void> setMute(String conversationId, bool muted) async {
    final uid = _requireUid();
    await _client
        .from('conversation_members')
        .update({'muted': muted})
        .eq('conversation_id', conversationId)
        .eq('user_id', uid);
  }

  @override
  Future<void> setArchived(String conversationId, bool archived) async {
    final uid = _requireUid();
    await _client
        .from('conversation_members')
        .update({'archived': archived})
        .eq('conversation_id', conversationId)
        .eq('user_id', uid);
  }

  @override
  Future<void> renameGroup(String conversationId, String name) async {
    await _client
        .from('conversations')
        .update({'name': name}).eq('id', conversationId);
  }

  @override
  Future<void> addGroupMembers(
      String conversationId, List<String> userIds) async {
    if (userIds.isEmpty) return;
    final rows = userIds
        .map((id) => {
              'conversation_id': conversationId,
              'user_id': id,
              'role': 'member',
            })
        .toList();
    await _client.from('conversation_members').insert(rows);
  }

  @override
  Future<void> removeGroupMember(
      String conversationId, String userId) async {
    await _client
        .from('conversation_members')
        .delete()
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
  }

  @override
  Future<void> leaveGroup(String conversationId) async {
    final uid = _requireUid();
    await removeGroupMember(conversationId, uid);
  }

  @override
  Future<void> markRead(String conversationId) async {
    final uid = _requireUid();
    await _client
        .from('conversation_members')
        .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('user_id', uid);
  }

  // ── Messages ──────────────────────────────────────────────────────────────
  @override
  Future<List<model.Message>> listMessages(
    String conversationId, {
    int limit = 100,
  }) async {
    final rows = await _client
        .from('messages')
        .select(
            'id, conversation_id, author_id, body, created_at, reply_to_id, '
            'pinned, is_ai')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .limit(limit);
    return rows.map<model.Message>(_messageFromRow).toList();
  }

  @override
  Stream<model.Message> subscribeToMessages(String conversationId) {
    final controller = StreamController<model.Message>();
    final channel = _client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            controller.add(_messageFromRow(row));
          },
        )
        .subscribe();
    controller.onCancel = () => _client.removeChannel(channel);
    return controller.stream;
  }

  @override
  Stream<model.Message> subscribeAllMessages({
    required List<String> conversationIds,
  }) {
    // One global channel; we filter client-side. Cheaper than N channels.
    final controller = StreamController<model.Message>();
    final allowed = conversationIds.toSet();
    final channel = _client
        .channel('messages:all-for-user')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final row = payload.newRecord;
            final convId = row['conversation_id'] as String?;
            if (convId != null && allowed.contains(convId)) {
              controller.add(_messageFromRow(row));
            }
          },
        )
        .subscribe();
    controller.onCancel = () => _client.removeChannel(channel);
    return controller.stream;
  }

  @override
  Future<model.Message> sendMessage(
    String conversationId,
    String body, {
    String? replyToId,
  }) async {
    final uid = _requireUid();
    final inserted = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'author_id': uid,
          'body': body,
          'reply_to_id': replyToId,
        })
        .select(
            'id, conversation_id, author_id, body, created_at, reply_to_id, '
            'pinned, is_ai')
        .single();
    return _messageFromRow(inserted);
  }

  @override
  Future<void> togglePin(String messageId, bool pinned) async {
    await _client.from('messages').update({'pinned': pinned}).eq('id', messageId);
  }

  @override
  Future<void> toggleReaction(String messageId, model.Reaction reaction) async {
    final uid = _requireUid();
    final kind = _reactionKind(reaction);
    // Try delete first; if no row affected, insert.
    final existing = await _client
        .from('reactions')
        .delete()
        .eq('message_id', messageId)
        .eq('user_id', uid)
        .eq('kind', kind)
        .select('message_id');
    if (existing.isEmpty) {
      await _client.from('reactions').insert({
        'message_id': messageId,
        'user_id': uid,
        'kind': kind,
      });
    }
  }

  // ── Uploads ───────────────────────────────────────────────────────────────
  @override
  Future<String> uploadAvatar(List<int> bytes, {required String filename}) async {
    final uid = _requireUid();
    final path = '$uid/$filename';
    await _client.storage.from('avatars').uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(upsert: true),
        );
    final url = _client.storage.from('avatars').getPublicUrl(path);
    // Persist on the profile so other clients can render it.
    await _client.from('profiles').update({'avatar_url': url}).eq('id', uid);
    return url;
  }

  @override
  Future<String> uploadAttachment(
    List<int> bytes, {
    required String conversationId,
    required String filename,
    required String mimeType,
  }) async {
    final uid = _requireUid();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$uid/$conversationId/$ts-$filename';
    await _client.storage.from('attachments').uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );
    final signed = await _client.storage
        .from('attachments')
        .createSignedUrl(path, 60 * 60 * 24 * 7); // 7 days
    return signed;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _requireUid() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Not signed in');
    }
    return id;
  }

  model.Message _messageFromRow(Map<String, dynamic> row) {
    return model.Message(
      id: row['id'] as String,
      authorId: row['author_id'] as String,
      text: row['body'] as String,
      sentAt: DateTime.parse(row['created_at'] as String).toLocal(),
      read: true,
      pinned: (row['pinned'] as bool?) ?? false,
      isAi: (row['is_ai'] as bool?) ?? false,
      replyToId: row['reply_to_id'] as String?,
    );
  }

  String _reactionKind(model.Reaction r) {
    switch (r) {
      case model.Reaction.heart:
        return 'heart';
      case model.Reaction.thumbsUp:
        return 'thumbs_up';
      case model.Reaction.laugh:
        return 'laugh';
      case model.Reaction.fire:
        return 'fire';
      case model.Reaction.eyes:
        return 'eyes';
    }
  }
}
