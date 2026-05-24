enum Reaction { heart, thumbsUp, laugh, fire, eyes }

extension ReactionGlyph on Reaction {
  String get glyph {
    switch (this) {
      case Reaction.heart:
        return '❤️';
      case Reaction.thumbsUp:
        return '👍';
      case Reaction.laugh:
        return '😂';
      case Reaction.fire:
        return '🔥';
      case Reaction.eyes:
        return '👀';
    }
  }
}

class Message {
  final String id;
  final String authorId;
  final String text;
  final DateTime sentAt;
  bool read;
  final List<Reaction> reactions;
  final bool isAi;
  bool pinned;
  final String? replyToId;

  Message({
    required this.id,
    required this.authorId,
    required this.text,
    required this.sentAt,
    this.read = true,
    List<Reaction>? reactions,
    this.isAi = false,
    this.pinned = false,
    this.replyToId,
  }) : reactions = reactions ?? <Reaction>[];
}
