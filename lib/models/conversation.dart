import 'message.dart';

class Conversation {
  final String id;
  final List<String> participantIds;
  final List<Message> messages;
  final bool isGroup;
  String? groupName;
  final String? groupAvatarId;
  bool muted;
  bool archived;
  int unread;

  Conversation({
    required this.id,
    required this.participantIds,
    required this.messages,
    this.isGroup = false,
    this.groupName,
    this.groupAvatarId,
    this.muted = false,
    this.archived = false,
    this.unread = 0,
  });

  Message? get lastMessage => messages.isEmpty ? null : messages.last;
}
