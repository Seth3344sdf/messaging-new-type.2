import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/avatar.dart';
import 'avatar_picker_screen.dart';
import 'briefing_tab.dart';
import 'chat_detail_screen.dart';
import 'chats_tab.dart';
import 'command_palette.dart';
import 'groups_tab.dart';

/// Three-pane layout for wide screens: nav rail (left) + list (middle) +
/// chat detail (right). Selection lives here so switching chats doesn't
/// change routes.
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _section = 0; // 0 chats, 1 groups, 2 briefing
  String? _selectedConversationId;

  bool get _isChatSection => _section == 0 || _section == 1;

  void _selectChat(String id) {
    setState(() => _selectedConversationId = id);
  }

  void _setSection(int i) {
    setState(() => _section = i);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final hairline = dark ? AppPalette.hairlineDark : AppPalette.hairline;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          _NavRail(
            section: _section,
            onTap: _setSection,
            onAvatarTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AvatarPickerScreen()),
            ),
            onSearch: () => CommandPalette.open(context),
          ),
          Container(width: 1, color: hairline),
          if (_isChatSection) ...[
            SizedBox(
              width: 340,
              child: ClipRect(
                child: _section == 0
                    ? ChatsTab(
                        onSelect: _selectChat,
                        selectedId: _selectedConversationId,
                      )
                    : GroupsTab(
                        onSelect: _selectChat,
                        selectedId: _selectedConversationId,
                      ),
              ),
            ),
            Container(width: 1, color: hairline),
            Expanded(
              child: _selectedConversationId == null
                  ? _emptyChat(context)
                  : ChatDetailScreen(
                      key: ValueKey(_selectedConversationId),
                      conversationId: _selectedConversationId!,
                    ),
            ),
          ] else
            const Expanded(child: BriefingTab()),
        ],
      ),
    );
  }

  Widget _emptyChat(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppPalette.bubbleOther,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppPalette.inkLight, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              _section == 1 ? 'Pick a group' : 'Pick a chat',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Or press ⌘K to search.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppPalette.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavRail extends StatelessWidget {
  final int section;
  final ValueChanged<int> onTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onSearch;

  const _NavRail({
    required this.section,
    required this.onTap,
    required this.onAvatarTap,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final app = context.watch<AppState>();

    return Container(
      width: 64,
      color: dark ? AppPalette.paperDark : AppPalette.paper,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onAvatarTap,
              child: AvatarView(avatarId: app.me.avatarId, size: 36),
            ),
            const SizedBox(height: 14),
            IconButton(
              tooltip: 'Search (⌘K)',
              icon: const Icon(Icons.search_rounded),
              color: AppPalette.inkMuted,
              onPressed: onSearch,
            ),
            const SizedBox(height: 4),
            _railItem(
              context,
              icon: Icons.chat_bubble_outline_rounded,
              activeIcon: Icons.chat_bubble_rounded,
              label: 'Chats',
              selected: section == 0,
              onTap: () => onTap(0),
            ),
            _railItem(
              context,
              icon: Icons.groups_outlined,
              activeIcon: Icons.groups_rounded,
              label: 'Groups',
              selected: section == 1,
              onTap: () => onTap(1),
            ),
            _railItem(
              context,
              icon: Icons.newspaper_outlined,
              activeIcon: Icons.newspaper_rounded,
              label: 'Briefing',
              selected: section == 2,
              onTap: () => onTap(2),
            ),
            const Spacer(),
            IconButton(
              tooltip: app.darkMode ? 'Light mode' : 'Dark mode',
              icon: Icon(
                app.darkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: AppPalette.inkMuted,
                size: 20,
              ),
              onPressed: () =>
                  context.read<AppState>().toggleDarkMode(!app.darkMode),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _railItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final muted = AppPalette.inkLight;
    final color = selected ? AppPalette.brand : muted;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? AppPalette.brandSoft
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(selected ? activeIcon : icon, color: color, size: 22),
        ),
      ),
    );
  }
}
