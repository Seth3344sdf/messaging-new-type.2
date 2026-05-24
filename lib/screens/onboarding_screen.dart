import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/avatar_library.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/avatar.dart';
import '../widgets/pill_button.dart';

/// Three-step first-run flow: name → status → avatar.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _initials = TextEditingController();
  final TextEditingController _status = TextEditingController();
  PaperTone _tone = PaperTone.paper;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _name.text = app.me.name;
    _initials.text = AvatarLibrary.initialsFrom(app.me.name);
    _status.text = app.workingOn == 'figuring it out' ? '' : app.workingOn;
    final current = app.specFor(app.me.avatarId);
    if (current != null) _tone = current.tone;
  }

  @override
  void dispose() {
    _name.dispose();
    _initials.dispose();
    _status.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      final name = _name.text.trim();
      if (name.isEmpty) return;
      context.read<AppState>().updateName(name);
      _initials.text = AvatarLibrary.initialsFrom(name).substring(
          0, AvatarLibrary.initialsFrom(name).length.clamp(0, 2));
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      final s = _status.text.trim();
      if (s.isNotEmpty) context.read<AppState>().updateWorkingOn(s);
      setState(() => _step = 2);
      return;
    }
    // Step 2 — finalize avatar and finish.
    final inits = _initials.text.trim().toUpperCase();
    final app = context.read<AppState>();
    app.updateMyAvatar(
      initials: inits.isEmpty ? null : inits,
      tone: _tone,
    );
    app.finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stepTitle(),
                    style: serifHeadline(
                      size: 32,
                      color: dark ? AppPalette.inkOnDark : AppPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stepBody(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppPalette.inkMuted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _stepContent(dark),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      _StepDots(current: _step),
                      const Spacer(),
                      PillButton(
                        label: _step == 2 ? 'Finish' : 'Continue',
                        onPressed: _canAdvance() ? _next : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _canAdvance() {
    switch (_step) {
      case 0:
        return _name.text.trim().isNotEmpty;
      case 1:
        return true; // status is optional
      case 2:
        return _initials.text.trim().isNotEmpty;
    }
    return false;
  }

  String _stepTitle() {
    switch (_step) {
      case 0:
        return 'What should we call you?';
      case 1:
        return 'What are you up to?';
      default:
        return 'Pick a look.';
    }
  }

  String _stepBody() {
    switch (_step) {
      case 0:
        return 'Your name shows up next to your messages.';
      case 1:
        return 'Optional. Edit anytime — "shipping", "heads down", "ooo".';
      default:
        return 'Two letters and a tone. You can change this whenever.';
    }
  }

  Widget _stepContent(bool dark) {
    switch (_step) {
      case 0:
        return _textField(_name, 'Your name', dark);
      case 1:
        return _textField(_status, 'shipping', dark);
      default:
        return _avatarStep(dark);
    }
  }

  Widget _textField(
      TextEditingController controller, String hint, bool dark) {
    return TextField(
      controller: controller,
      autofocus: true,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: dark ? AppPalette.surfaceDark : AppPalette.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          borderSide: const BorderSide(color: AppPalette.brand, width: 1.5),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _avatarStep(bool dark) {
    final preview = AvatarLibrary.custom(
      id: 'preview',
      initials: _initials.text.trim().isEmpty
          ? '··'
          : _initials.text.trim().toUpperCase(),
      tone: _tone,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: AvatarSpecView(spec: preview, size: 96)),
        const SizedBox(height: 20),
        Text('Initials',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppPalette.inkLight,
                )),
        const SizedBox(height: 6),
        TextField(
          controller: _initials,
          maxLength: 2,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          ],
          style: Theme.of(context).textTheme.titleLarge,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: dark ? AppPalette.surfaceDark : AppPalette.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppPalette.brand),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Text('Tone',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppPalette.inkLight,
                )),
        const SizedBox(height: 10),
        Row(
          children: PaperTone.values.map((t) {
            final swatch = AvatarLibrary.custom(
              id: 'tone_$t',
              initials: _initials.text.trim().isEmpty
                  ? '··'
                  : _initials.text.trim().toUpperCase(),
              tone: t,
            );
            final selected = t == _tone;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _tone = t),
                child: AvatarSpecView(
                    spec: swatch, size: 52, selected: selected),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StepDots extends StatelessWidget {
  final int current;
  const _StepDots({required this.current});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final filled = i == current;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            width: filled ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: filled ? AppPalette.brand : AppPalette.hairline,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
