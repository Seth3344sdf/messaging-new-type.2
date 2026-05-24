import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/avatar_library.dart';
import '../models/user.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/avatar.dart';
import '../widgets/pill_button.dart';
import '../widgets/presence_dot.dart';
import 'chat_detail_screen.dart';

enum NewChatAction { menu, direct, group, invite }

class NewChatSheet extends StatelessWidget {
  final NewChatAction initialAction;
  const NewChatSheet({super.key, this.initialAction = NewChatAction.menu});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    // If a specific action was requested, open straight into it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (initialAction) {
        case NewChatAction.direct:
          _openUserPicker(context, andPop: true);
          break;
        case NewChatAction.group:
          _openNewGroup(context, andPop: true);
          break;
        case NewChatAction.invite:
          _openInvite(context, andPop: true);
          break;
        case NewChatAction.menu:
          break;
      }
    });

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: dark ? AppPalette.surfaceDark : AppPalette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(
            color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Handle(),
            const SizedBox(height: 8),
            _Option(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'one-on-one',
              detail: 'just two of you',
              onTap: () => _openUserPicker(context, andPop: true),
            ),
            _Option(
              icon: Icons.groups_outlined,
              label: 'group',
              detail: 'pick people, name it, go',
              onTap: () => _openNewGroup(context, andPop: true),
            ),
            _Option(
              icon: Icons.link_rounded,
              label: 'invite someone',
              detail: 'send a link',
              onTap: () => _openInvite(context, andPop: true),
            ),
          ],
        ),
      ),
    );
  }

  void _openUserPicker(BuildContext context, {bool andPop = false}) {
    if (andPop) Navigator.of(context).pop();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _UserPicker(),
    );
  }

  void _openNewGroup(BuildContext context, {bool andPop = false}) {
    if (andPop) Navigator.of(context).pop();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewGroupSheet(),
    );
  }

  void _openInvite(BuildContext context, {bool andPop = false}) {
    if (andPop) Navigator.of(context).pop();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _InviteSheet(),
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppPalette.hairline,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;
  const _Option({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppPalette.bubbleOther,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppPalette.ink, size: 18),
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppPalette.inkLight),
      onTap: onTap,
    );
  }
}

class _UserPicker extends StatefulWidget {
  const _UserPicker();
  @override
  State<_UserPicker> createState() => _UserPickerState();
}

class _UserPickerState extends State<_UserPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final filtered = app.users
        .where((u) => _q.isEmpty || u.name.toLowerCase().contains(_q.toLowerCase()))
        .toList();

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Container(
        decoration: BoxDecoration(
          color: dark ? AppPalette.paperDark : AppPalette.paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            _Handle(),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('start a chat', style: theme.textTheme.displaySmall),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppPalette.inkLight),
                hintText: 'search',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: AppPalette.inkLight,
                ),
                filled: true,
                fillColor: dark ? AppPalette.surfaceDark : AppPalette.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppPalette.ink),
                ),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
                ),
                itemBuilder: (context, i) {
                  final u = filtered[i];
                  return ListTile(
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AvatarView(avatarId: u.avatarId, size: 42),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: PresenceDot(presence: u.presence, size: 11),
                        ),
                      ],
                    ),
                    title: Text(u.name, style: theme.textTheme.titleMedium),
                    subtitle: u.status != null ? Text(u.status!) : null,
                    onTap: () {
                      final c = context.read<AppState>().createOneOnOne(u.id);
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(conversationId: c.id),
                      ));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewGroupSheet extends StatefulWidget {
  const _NewGroupSheet();
  @override
  State<_NewGroupSheet> createState() => _NewGroupSheetState();
}

class _NewGroupSheetState extends State<_NewGroupSheet> {
  final TextEditingController _name = TextEditingController();
  final Set<String> _selected = {};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final name = _name.text.trim();
    final previewInitials =
        name.isEmpty ? '··' : AvatarLibrary.initialsFrom(name);
    final previewSpec = AvatarLibrary.custom(
      id: 'new_group_preview',
      initials: previewInitials,
      tone: PaperTone.warm,
    );

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Container(
        decoration: BoxDecoration(
          color: dark ? AppPalette.paperDark : AppPalette.paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            _Handle(),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('New group', style: theme.textTheme.displaySmall),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                AvatarSpecView(spec: previewSpec, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _name,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'name it',
                      filled: true,
                      fillColor:
                          dark ? AppPalette.surfaceDark : AppPalette.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: dark
                              ? AppPalette.hairlineDark
                              : AppPalette.hairline,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: dark
                              ? AppPalette.hairlineDark
                              : AppPalette.hairline,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppPalette.ink),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'who is in',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: AppPalette.inkLight),
              ),
            ),
            Expanded(
              child: ListView(
                children: app.users.map((u) {
                  final checked = _selected.contains(u.id);
                  return CheckboxListTile(
                    value: checked,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(u.id);
                        } else {
                          _selected.remove(u.id);
                        }
                      });
                    },
                    activeColor: AppPalette.ink,
                    checkboxShape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    secondary: AvatarView(avatarId: u.avatarId, size: 34),
                    title: Text(u.name),
                    subtitle: _presenceLabel(u.presence),
                    controlAffinity: ListTileControlAffinity.trailing,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('cancel',
                      style: TextStyle(color: AppPalette.inkMuted)),
                ),
                const Spacer(),
                PillButton(
                  label: 'Create',
                  onPressed: _selected.isEmpty || _name.text.trim().isEmpty
                      ? null
                      : () {
                          final c = context.read<AppState>().createGroup(
                                name: _name.text.trim(),
                                memberIds: _selected.toList(),
                              );
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                ChatDetailScreen(conversationId: c.id),
                          ));
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget? _presenceLabel(Presence p) {
    switch (p) {
      case Presence.online:
        return const Text('online');
      case Presence.idle:
        return const Text('idle');
      case Presence.offline:
        return const Text('offline');
    }
  }
}

class _InviteSheet extends StatelessWidget {
  const _InviteSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    const link = 'messaging.app/i/warmly-Ax8C2';
    return Container(
      decoration: BoxDecoration(
        color: dark ? AppPalette.paperDark : AppPalette.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Handle(),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('invite someone', style: theme.textTheme.displaySmall),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: dark ? AppPalette.surfaceDark : AppPalette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
              ),
            ),
            child: Column(
              children: [
                const _QrPlaceholder(size: 150),
                const SizedBox(height: 14),
                Text(link,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 12),
                PillButton(
                  icon: Icons.copy_rounded,
                  label: 'copy link',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('copied (well, pretend)')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPlaceholder extends StatelessWidget {
  final double size;
  const _QrPlaceholder({required this.size});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? AppPalette.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
        ),
      ),
      child: CustomPaint(painter: _QrPainter(dark: dark)),
    );
  }
}

class _QrPainter extends CustomPainter {
  final bool dark;
  _QrPainter({required this.dark});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = dark ? AppPalette.inkOnDark : AppPalette.ink;
    final cell = size.width / 21;
    const seed = 0x9E3779B9;
    var state = seed;
    int rnd() {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      return state;
    }

    for (var y = 0; y < 21; y++) {
      for (var x = 0; x < 21; x++) {
        final isFinder = (x < 7 && y < 7) ||
            (x > 13 && y < 7) ||
            (x < 7 && y > 13);
        if (isFinder) {
          final fx = x % 7;
          final fy = y % 7;
          final outer = fx == 0 || fx == 6 || fy == 0 || fy == 6;
          final inner = fx >= 2 && fx <= 4 && fy >= 2 && fy <= 4;
          if (outer || inner) {
            canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), p);
          }
        } else if (rnd() % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
