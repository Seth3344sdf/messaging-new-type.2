import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide Presence;

import '../models/conversation.dart';
import '../models/message.dart' as model;
import '../models/user.dart';
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
