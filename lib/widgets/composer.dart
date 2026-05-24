import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../screens/encryption_sheet.dart';
import '../screens/voice_overlay.dart';
import '../theme/colors.dart';
import 'attachment_sheet.dart';

typedef SlashHandler = void Function(String fullCommand);

class SlashCommand {
  final String name; // includes leading "/"
  final String hint;
  final IconData icon;
  const SlashCommand(this.name, this.hint, this.icon);
}

const _slashCommands = <SlashCommand>[
  SlashCommand('/summarize', 'catch me up on what i missed', Icons.auto_awesome),
  SlashCommand('/find', 'find a message or decision', Icons.search_rounded),
  SlashCommand('/remind', 'set a reminder', Icons.alarm_rounded),
  SlashCommand('/decide', 'capture a decision and pin it', Icons.push_pin_outlined),
];

class Composer extends StatefulWidget {
  final void Function(String text) onSend;
  final SlashHandler? onSlashCommand;
  final void Function(AttachmentKind kind)? onAttach;
  final String hint;

  const Composer({
    super.key,
    required this.onSend,
    this.onSlashCommand,
    this.onAttach,
    this.hint = 'message',
  });

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
      // For slash menu visibility — just rebuild.
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    if (v.startsWith('/') && widget.onSlashCommand != null) {
      widget.onSlashCommand!(v);
    } else {
      widget.onSend(v);
    }
    _ctrl.clear();
  }

  void _pickSlash(SlashCommand cmd) {
    _ctrl.text = '${cmd.name} ';
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    _focus.requestFocus();
  }

  Future<void> _openAttach() async {
    final kind = await AttachmentSheet.open(context);
    if (kind == null) return;
    if (kind == AttachmentKind.voice) {
      await _openVoice();
      return;
    }
    widget.onAttach?.call(kind);
  }

  Future<void> _openVoice() async {
    final result = await Navigator.of(context).push<String>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => const VoiceOverlay(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    if (result != null && result.isNotEmpty) {
      _ctrl.text = result;
      _focus.requestFocus();
    }
  }

  bool get _showSlashMenu {
    final t = _ctrl.text;
    if (!t.startsWith('/')) return false;
    // Show the menu while the user is typing the command itself (no space
    // yet) so they get auto-complete hints.
    return !t.contains(' ');
  }

  List<SlashCommand> get _filteredSlash {
    final t = _ctrl.text.toLowerCase();
    return _slashCommands
        .where((c) => c.name.startsWith(t.isEmpty ? '/' : t))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final fieldColor = dark ? AppPalette.surfaceDark : AppPalette.surface;
    final hairline = dark ? AppPalette.hairlineDark : AppPalette.hairline;

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showSlashMenu) _slashMenu(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _circleIcon(
                  icon: Icons.add_rounded,
                  onTap: _openAttach,
                  tooltip: 'Attach',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: fieldColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: hairline),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 6,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: widget.hint,
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: AppPalette.inkLight,
                        ),
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _hasText
                      ? _circleIcon(
                          key: const ValueKey('send'),
                          icon: Icons.arrow_upward_rounded,
                          onTap: _send,
                          filled: true,
                          tooltip: 'send',
                        )
                      : _circleIcon(
                          key: const ValueKey('mic'),
                          icon: Icons.mic_none_rounded,
                          onTap: _openVoice,
                          tooltip: 'voice',
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => EncryptionSheet.open(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded,
                            size: 11, color: AppPalette.presence),
                        const SizedBox(width: 4),
                        Text(
                          'end-to-end encrypted',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppPalette.presence,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'type / for commands',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.inkLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slashMenu(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final items = _filteredSlash;
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: BoxDecoration(
        color: dark ? AppPalette.surfaceDark : AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
        ),
        boxShadow: AppPalette.softShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items
            .map(
              (c) => InkWell(
                onTap: () => _pickSlash(c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(c.icon, size: 16, color: AppPalette.inkMuted),
                      const SizedBox(width: 10),
                      Text(
                        c.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          fontFamilyFallback: const [
                            'JetBrains Mono',
                            'SF Mono',
                            'Menlo',
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          c.hint,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppPalette.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ).animate().fadeIn(duration: 160.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _circleIcon({
    Key? key,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
    String? tooltip,
  }) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final bg = filled
        ? AppPalette.brand
        : (dark ? AppPalette.surfaceDark : AppPalette.surface);
    final fg = filled
        ? Colors.white
        : (dark ? AppPalette.inkOnDark : AppPalette.ink);
    final border = filled
        ? null
        : Border.all(
            color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
          );
    final btn = Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: border,
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: fg, size: 20),
        ),
      ),
    );
    return Semantics(
      label: tooltip,
      button: true,
      child: SizedBox(width: 42, height: 42, child: btn),
    );
  }
}
