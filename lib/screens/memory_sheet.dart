import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/message.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/avatar.dart';
import '../widgets/message_text.dart';

/// "What this chat remembers" — a calm surface that lists pinned decisions
/// from a conversation. The product thesis: conversation becomes knowledge.
class MemorySheet extends StatelessWidget {
  final String conversationId;
  const MemorySheet({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final pinned = app.pinnedDecisions(conversationId);

    return FractionallySizedBox(
      heightFactor: 0.75,
      child: Container(
        decoration: BoxDecoration(
          color: dark ? AppPalette.paperDark : AppPalette.paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      dark ? AppPalette.hairlineDark : AppPalette.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('memory', style: theme.textTheme.displaySmall),
                        const SizedBox(height: 4),
                        Text(
                          'what this chat decided.\nlong-press any message to pin it here.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppPalette.inkMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pinned.isEmpty
                  ? _empty(context)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: pinned.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final m = pinned[i];
                        return _DecisionCard(message: m);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.push_pin_outlined,
                size: 26, color: AppPalette.decision.withValues(alpha: 0.65)),
            const SizedBox(height: 10),
            Text(
              'nothing pinned yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: AppPalette.inkMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'long-press a message and tap "pin as decision".',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  final Message message;
  const _DecisionCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final author = app.userById(message.authorId);
    final when = _format(message.sentAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? AppPalette.surfaceDark : AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarView(avatarId: author.avatarId, size: 26),
              const SizedBox(width: 8),
              Text(
                author.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(when, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          MessageText(
            text: message.text,
            color: dark ? AppPalette.inkOnDark : AppPalette.ink,
            fromMe: false,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: dark
                      ? AppPalette.decisionSoftDark
                      : AppPalette.decisionSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.push_pin_rounded,
                        size: 11, color: AppPalette.decision),
                    const SizedBox(width: 4),
                    Text(
                      'decision',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.decision,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.read<AppState>().togglePin(message),
                child: Text(
                  'unpin',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.inkLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _format(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${t.month}/${t.day}';
  }
}
