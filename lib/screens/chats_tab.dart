import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/conversation.dart';
import '../models/user.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/avatar.dart';
import '../widgets/presence_dot.dart';
import 'chat_detail_screen.dart';
import 'command_palette.dart';
import 'new_chat_sheet.dart';
import 'profile_tab.dart';

class ChatsTab extends StatefulWidget {
  final void Function(String conversationId)? onSelect;
  final String? selectedId;
  const ChatsTab({super.key, this.onSelect, this.selectedId});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final visible = app.directChats;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileTab()),
            ),
            child:
                Center(child: AvatarView(avatarId: app.me.avatarId, size: 34)),
          ),
        ),
        leadingWidth: 60,
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: app.darkMode ? 'Light mode' : 'Dark mode',
            icon: Icon(
              app.darkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () =>
                context.read<AppState>().toggleDarkMode(!app.darkMode),
          ),
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openNewChat(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => CommandPalette.open(context),
              child: Container(
                decoration: BoxDecoration(
                  color: dark ? AppPalette.surfaceDark : AppPalette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: AppPalette.inkLight, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'search people, chats, messages',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppPalette.inkLight,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: dark
                            ? AppPalette.paperDark
                            : AppPalette.paper,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: dark
                              ? AppPalette.hairlineDark
                              : AppPalette.hairline,
                        ),
                      ),
                      child: const Text(
                        '⌘K',
                        style: TextStyle(
                          color: AppPalette.inkLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontFamilyFallback: [
                            'JetBrains Mono',
                            'SF Mono',
                            'Menlo'
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppPalette.brand,
              onRefresh: () => context.read<AppState>().refresh(),
              child: visible.isEmpty
                  ? ListView(
                      // ListView so RefreshIndicator can still pull on empty state
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [SizedBox(height: 200, child: _empty(theme))],
                    )
                  : _buildGrouped(context, visible),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrouped(BuildContext context, List<Conversation> chats) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    // Newest first.
    final sorted = [...chats]
      ..sort((a, b) {
        final at = a.lastMessage?.sentAt ?? DateTime(2000);
        final bt = b.lastMessage?.sentAt ?? DateTime(2000);
        return bt.compareTo(at);
      });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(const Duration(days: 6));

    final groups = <String, List<Conversation>>{
      'Today': [],
      'Yesterday': [],
      'This week': [],
      'Earlier': [],
    };

    for (final c in sorted) {
      final t = c.lastMessage?.sentAt;
      final d = t == null ? null : DateTime(t.year, t.month, t.day);
      if (d == null) {
        groups['Earlier']!.add(c);
      } else if (d == today) {
        groups['Today']!.add(c);
      } else if (d == yesterday) {
        groups['Yesterday']!.add(c);
      } else if (!d.isBefore(weekStart)) {
        groups['This week']!.add(c);
      } else {
        groups['Earlier']!.add(c);
      }
    }

    final items = <Widget>[];
    var rowIndex = 0;
    groups.forEach((label, list) {
      if (list.isEmpty) return;
      items.add(_GroupHeader(label: label));
      for (var i = 0; i < list.length; i++) {
        items.add(_ChatRow(
          conversation: list[i],
          onSelect: widget.onSelect,
          selected: widget.selectedId == list[i].id,
        )
            .animate()
            .fadeIn(duration: 200.ms, delay: (rowIndex * 18).ms)
            .slideY(
              begin: 0.03,
              end: 0,
              duration: 200.ms,
              curve: Curves.easeOutCubic,
            ));
        if (i < list.length - 1) {
          items.add(Divider(
            height: 1,
            indent: 82,
            color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
          ));
        }
        rowIndex++;
      }
    });

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: items,
    );
  }

  Widget _empty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppPalette.brandSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppPalette.brand, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              'Quiet in here.',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the + button to start your first chat, or press ⌘K to find someone.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppPalette.inkMuted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  void _openNewChat(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewChatSheet(),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppPalette.inkLight,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  final Conversation conversation;
  final void Function(String conversationId)? onSelect;
  final bool selected;
  const _ChatRow({
    required this.conversation,
    this.onSelect,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final theme = Theme.of(context);

    final otherId = conversation.participantIds.firstWhere(
      (id) => id != app.me.id && id != app.pulse.id,
      orElse: () => app.pulse.id,
    );
    final other = app.userById(otherId);
    final title = other.name;
    final avatarId = other.avatarId;

    final last = conversation.lastMessage;
    final preview = last == null
        ? 'no messages yet'
        : (last.authorId == app.me.id ? 'you: ${last.text}' : last.text);
    final time = last == null ? '' : _formatTime(last.sentAt);

    return Dismissible(
      key: ValueKey(conversation.id),
      background: _swipeBg(
        color: AppPalette.bubbleOther,
        text: conversation.muted ? 'unmute' : 'mute',
        icon: Icons.notifications_off_rounded,
        alignLeft: true,
      ),
      secondaryBackground: _swipeBg(
        color: AppPalette.ink,
        textColor: Colors.white,
        text: conversation.archived ? 'unarchive' : 'archive',
        icon: Icons.archive_outlined,
        alignLeft: false,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          app.muteConversation(conversation.id);
        } else {
          app.archiveConversation(conversation.id);
        }
        return false;
      },
      child: InkWell(
        onTap: () {
          if (onSelect != null) {
            onSelect!(conversation.id);
          } else {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  ChatDetailScreen(conversationId: conversation.id),
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
                child: conversation.unread > 0
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AvatarView(avatarId: avatarId, size: 52),
                  if (other.presence != Presence.offline)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: PresenceDot(presence: other.presence, size: 13),
                    ),
                ],
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
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: conversation.unread > 0
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
                        if (conversation.muted)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.notifications_off_rounded,
                                size: 14, color: AppPalette.inkLight),
                          ),
                        if (conversation.unread > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppPalette.unread,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${conversation.unread}',
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
      ),
    );
  }

  Widget _swipeBg({
    required Color color,
    required String text,
    required IconData icon,
    required bool alignLeft,
    Color? textColor,
  }) {
    final fg = textColor ?? AppPalette.ink;
    return Container(
      color: color,
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment:
            alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (alignLeft) Icon(icon, color: fg, size: 18),
          if (alignLeft) const SizedBox(width: 8),
          Text(text,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
          if (!alignLeft) const SizedBox(width: 8),
          if (!alignLeft) Icon(icon, color: fg, size: 18),
        ],
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
