import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/avatar.dart';
import 'avatar_picker_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final TextEditingController _name;
  late final TextEditingController _status;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _name = TextEditingController(text: app.me.name);
    _status = TextEditingController(text: app.workingOn);
  }

  @override
  void dispose() {
    _name.dispose();
    _status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AvatarPickerScreen()),
              ),
              child: Column(
                children: [
                  AvatarView(avatarId: app.me.avatarId, size: 96),
                  const SizedBox(height: 8),
                  Text(
                    'tap to change',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _LabeledField(
            label: 'name',
            controller: _name,
            onSubmit: (v) => context.read<AppState>().updateName(v),
            hint: 'your name',
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'up to',
            controller: _status,
            onSubmit: (v) => context.read<AppState>().updateWorkingOn(v),
            hint: 'what are you up to?',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in const [
                ('In a meeting', '30m'),
                ('Heads down', '2h'),
                ('Out for lunch', '1h'),
                ('Back tomorrow', '1d'),
              ])
                _StatusPreset(
                  label: preset.$1,
                  expiry: preset.$2,
                  onTap: () {
                    final v = '${preset.$1} · clears in ${preset.$2}';
                    _status.text = v;
                    context.read<AppState>().updateWorkingOn(v);
                  },
                ),
              _StatusPreset(
                label: 'Clear',
                expiry: '',
                onTap: () {
                  _status.text = '';
                  context.read<AppState>().updateWorkingOn('');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _Section(title: 'preferences', children: [
            _SwitchRow(
              label: 'notifications',
              icon: Icons.notifications_none_rounded,
              value: app.notifications,
              onChanged: app.toggleNotifications,
            ),
            _SwitchRow(
              label: 'do not disturb',
              icon: Icons.do_not_disturb_alt_rounded,
              value: app.doNotDisturb,
              onChanged: app.toggleDnd,
            ),
            _SwitchRow(
              label: 'dark mode',
              icon: Icons.dark_mode_outlined,
              value: app.darkMode,
              onChanged: app.toggleDarkMode,
            ),
            _SwitchRow(
              label: 'read receipts',
              icon: Icons.done_all_rounded,
              value: app.readReceipts,
              onChanged: app.toggleReadReceipts,
            ),
          ]),
          const SizedBox(height: 16),
          // TODO(real-backend): wire to real key management / device attestation.
          _Section(title: 'safe stuff', children: const [
            _SafeRow(
              label: 'end-to-end encrypted',
              detail: 'your messages stay between you and them.',
            ),
            _SafeRow(
              label: 'device verified',
              detail: 'this device is set up.',
            ),
            _SafeRow(
              label: 'session active',
              detail: 'signed in here.',
            ),
          ]),
          const SizedBox(height: 28),
          Center(
            child: TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('sign out is just for show in this demo.')),
                );
              },
              icon: const Icon(Icons.logout_rounded, color: AppPalette.inkLight),
              label: Text(
                'sign out',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppPalette.inkLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final String hint;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.onSubmit,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppPalette.inkLight,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: dark ? AppPalette.surfaceDark : AppPalette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
            ),
          ),
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            onSubmitted: onSubmit,
            onEditingComplete: () => onSubmit(controller.text),
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: AppPalette.inkLight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.inkLight,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: dark ? AppPalette.surfaceDark : AppPalette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: AppPalette.inkMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppPalette.ink,
            activeTrackColor: AppPalette.ink.withValues(alpha: 0.85),
          ),
        ],
      ),
    );
  }
}

class _StatusPreset extends StatelessWidget {
  final String label;
  final String expiry;
  final VoidCallback onTap;
  const _StatusPreset({
    required this.label,
    required this.expiry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: dark ? AppPalette.surfaceDark : AppPalette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (expiry.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                expiry,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.inkLight,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SafeRow extends StatelessWidget {
  final String label;
  final String detail;

  const _SafeRow({required this.label, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppPalette.presence.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.lock_rounded,
                color: AppPalette.presence, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                Text(detail,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
