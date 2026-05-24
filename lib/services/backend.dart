import 'dart:async';

import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';

/// Backend abstraction. Both the live Supabase implementation and the local
/// mock-data fallback implement this interface so the UI can be swapped over
/// without changing screen code.
///
/// Today only [SupabaseBackend] is implemented. Mock-data mode still runs
/// through the existing [AppState] until that screen-by-screen refactor lands
/// (see BACKEND.md → "Phase 2 — wire AppState through Backend").
abstract class Backend {
  // ── Auth ──────────────────────────────────────────────────────────────────
  Stream<AppUser?> get authChanges;
  AppUser? get currentUser;
  Future<void> signInWithMagicLink(String email);
  Future<void> signOut();

  // ── Profiles ──────────────────────────────────────────────────────────────
  Future<void> updateProfile({String? name, String? status, String? initials});
  Future<List<AppUser>> listUsers();

  /// Has the signed-in user finished onboarding?
  Future<bool> isOnboarded();
  Future<void> markOnboarded();

  // ── Conversations ─────────────────────────────────────────────────────────
  Future<List<Conversation>> listConversations();
  Future<Conversation> createOneOnOne(String otherUserId);
  Future<Conversation> createGroup({
    required String name,
    required List<String> memberIds,
  });
  Future<void> setMute(String conversationId, bool muted);
  Future<void> setArchived(String conversationId, bool archived);
  Future<void> markRead(String conversationId);

  // ── Messages ──────────────────────────────────────────────────────────────
  Future<List<Message>> listMessages(String conversationId, {int limit = 100});
  Stream<Message> subscribeToMessages(String conversationId);

  /// Single subscription that fans out new messages from any conversation the
  /// user is a member of. Useful for keeping the list-side cache live without
  /// opening one channel per conversation.
  Stream<Message> subscribeAllMessages({required List<String> conversationIds});
  Future<Message> sendMessage(
    String conversationId,
    String body, {
    String? replyToId,
  });
  Future<void> togglePin(String messageId, bool pinned);
  Future<void> toggleReaction(String messageId, Reaction reaction);
}
