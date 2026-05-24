import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/conversation.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/avatar.dart';
import 'chat_detail_screen.dart';
import 'new_chat_sheet.dart';

class GroupsTab extends StatelessWidget {
  final void Function(String conversationId)? onSelect;
  final String? selectedId;
  const GroupsTab({super.key, this.onSelect, this.selectedId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final groups = app.groupChats;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            tooltip: 'New group',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _newGroup(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: groups.isEmpty
          ? _empty(context)
          : ListView.separated(
              padding: const EdgeInsets.only(top: 4, bottom: 24),
              itemCount: groups.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 84,
                color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
              ),
              itemBuilder: (context, i) {
                final g = groups[i];
                return _GroupRow(
                  group: g,
                  onSelect: onSelect,
                  selected: selectedId == g.id,
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: (i * 24).ms)
                    .slideY(
                      begin: 0.04,
                      end: 0,
                      duration: 200.ms,
                      curve: Curves.easeOutCubic,
                    );
              },
            ),
    );
  }

  Widget _empty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'no groups yet',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'a group is just a chat with more people.\nstart one with the + button.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: AppPalette.inkMuted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  void _newGroup(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewChatSheet(initialAction: NewChatAction.group),
    );
  }
}

class _GroupRow extends StatelessWidget {
  final Conversation group;
  final void Function(String conversationId)? onSelect;
  final bool selected;
  const _GroupRow({
    required this.group,
    this.onSelect,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final theme = Theme.of(context);
    final last = group.lastMessage;
    final memberCount = group.participantIds
        .where((id) => id != app.pulse.id)
        .length;

    final preview = last == null
        ? 'no messages yet'
        : (last.authorId == app.me.id
            ? 'you: ${last.text}'
            : last.isAi
                ? 'pulse: ${last.text}'
                : '${app.userById(last.authorId).name}: ${last.text}');

    final time = last == null ? '' : _formatTime(last.sentAt);

    return InkWell(
      onTap: () {
        if (onSelect != null) {
          onSelect!(group.id);
        } else {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChatDetailScreen(conversationId: group.id),
          ));
        }
      },
      child: Container(
        color: selected
            ? (Theme.of(context).brightness == Brightness.dark
                ? AppPalette.surfaceDark
                : AppPalette.surface)
            : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(6, 12, 16, 12),
        child: Row(
          children: [
            SizedBox(
              width: 10,
              child: group.unread > 0
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppPalette.unread,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            AvatarView(
              avatarId: group.groupAvatarId ?? 'ai:pulse',
              size: 52,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.groupName ?? 'group',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: group.unread > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(time, style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '$memberCount people · ',
                        style: theme.textTheme.bodySmall,
                      ),
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppPalette.inkMuted,
                          ),
                        ),
                      ),
                      if (group.unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppPalette.unread,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${group.unread}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
    if (sameDay) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    final diff = now.difference(t).inDays;
    if (diff < 7) {
      const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
      return days[t.weekday - 1];
    }
    return '${t.month}/${t.day}';
  }
}
