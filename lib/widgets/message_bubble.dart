import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/message.dart';
import '../theme/colors.dart';
import 'avatar.dart';
import 'message_text.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool fromMe;
  final bool showAvatar;
  final String? authorName;
  final String? authorAvatarId;
  final bool showRead;
  final void Function(Reaction r) onReact;
  final VoidCallback? onTogglePin;
  final VoidCallback? onReply;
  final Widget? replyPreview;

  const MessageBubble({
    super.key,
    required this.message,
    required this.fromMe,
    required this.onReact,
    this.onTogglePin,
    this.onReply,
    this.replyPreview,
    this.showAvatar = false,
    this.authorName,
    this.authorAvatarId,
    this.showRead = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAi = message.isAi;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final selfBg = AppPalette.bubbleSelf;
    final selfText = AppPalette.bubbleSelfText;
    final otherBg = isAi
        ? (dark ? AppPalette.aiSoftDark : AppPalette.aiSoft)
        : (dark ? AppPalette.bubbleOtherDark : AppPalette.bubbleOther);
    final otherText = dark ? AppPalette.inkOnDark : AppPalette.ink;

    final aiBorder = isAi
        ? const Border(
            left: BorderSide(color: AppPalette.ai, width: 2),
          )
        : null;

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.74,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fromMe ? selfBg : otherBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(fromMe ? 18 : 6),
            bottomRight: Radius.circular(fromMe ? 6 : 18),
          ),
          border: aiBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAi)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: AppPalette.ai, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      'Pulse',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.ai,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            if (!fromMe && authorName != null && !isAi)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  authorName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.hueForMember(message.authorId),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (replyPreview != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: replyPreview!,
              ),
            MessageText(
              text: message.text,
              color: fromMe ? selfText : otherText,
              fromMe: fromMe,
            ),
            if (message.pinned)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.push_pin_rounded,
                      size: 12,
                      color: fromMe
                          ? selfText.withValues(alpha: 0.85)
                          : AppPalette.decision,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'pinned as decision',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: fromMe
                            ? selfText.withValues(alpha: 0.85)
                            : AppPalette.decision,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 4,
                  children: message.reactions
                      .map((r) => Text(r.glyph, style: const TextStyle(fontSize: 16)))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );

    final row = Row(
      mainAxisAlignment:
          fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!fromMe && showAvatar && authorAvatarId != null) ...[
          AvatarView(avatarId: authorAvatarId!, size: 28),
          const SizedBox(width: 8),
        ] else if (!fromMe) ...[
          const SizedBox(width: 36),
        ],
        Flexible(
          child: GestureDetector(
            onLongPress: () => _showReactionPicker(context),
            child: bubble.animate().fadeIn(duration: 140.ms).scaleXY(
                  begin: 0.95,
                  end: 1.0,
                  duration: 200.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),
        ),
        if (fromMe) const SizedBox(width: 8),
      ],
    );

    return Column(
      crossAxisAlignment:
          fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        row,
        if (fromMe)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded,
                    size: 9, color: AppPalette.presence),
                const SizedBox(width: 3),
                Text(
                  showRead
                      ? (message.read ? 'seen' : 'sent')
                      : 'encrypted',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.inkLight,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showReactionPicker(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ReactionPicker(
        message: message,
        onPick: (r) {
          onReact(r);
          entry.remove();
        },
        onTogglePin: onTogglePin == null
            ? null
            : () {
                onTogglePin!();
                entry.remove();
              },
        onReply: onReply == null
            ? null
            : () {
                onReply!();
                entry.remove();
              },
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _ReactionPicker extends StatelessWidget {
  final Message message;
  final void Function(Reaction r) onPick;
  final VoidCallback? onTogglePin;
  final VoidCallback? onReply;
  final VoidCallback onDismiss;
  const _ReactionPicker({
    required this.message,
    required this.onPick,
    required this.onDismiss,
    this.onTogglePin,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
            child: Container(color: Colors.black.withValues(alpha: 0.15)),
          ),
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: dark ? AppPalette.surfaceDark : AppPalette.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: dark
                          ? AppPalette.hairlineDark
                          : AppPalette.hairline,
                    ),
                    boxShadow: AppPalette.softShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: Reaction.values
                        .map((r) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: GestureDetector(
                                onTap: () => onPick(r),
                                child: Text(
                                  r.glyph,
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                if (onReply != null || onTogglePin != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onReply != null)
                        _actionChip(
                          context,
                          icon: Icons.reply_rounded,
                          label: 'reply',
                          onTap: onReply!,
                        ),
                      if (onReply != null && onTogglePin != null)
                        const SizedBox(width: 8),
                      if (onTogglePin != null)
                        _actionChip(
                          context,
                          icon: message.pinned
                              ? Icons.push_pin_rounded
                              : Icons.push_pin_outlined,
                          label:
                              message.pinned ? 'unpin' : 'pin as decision',
                          onTap: onTogglePin!,
                          iconColor: AppPalette.decision,
                        ),
                    ],
                  ),
                ],
              ],
            )
                .animate()
                .scale(
                  begin: const Offset(0.92, 0.92),
                  duration: 160.ms,
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(duration: 120.ms),
          ),
        ),
      ],
    );
  }

  Widget _actionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: dark ? AppPalette.surfaceDark : AppPalette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
          ),
          boxShadow: AppPalette.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: iconColor ??
                    (dark ? AppPalette.inkOnDark : AppPalette.ink)),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
