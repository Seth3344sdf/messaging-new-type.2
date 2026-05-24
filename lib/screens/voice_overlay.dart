import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/colors.dart';
import '../widgets/pill_button.dart';
import '../widgets/waveform.dart';

class VoiceOverlay extends StatefulWidget {
  const VoiceOverlay({super.key});

  @override
  State<VoiceOverlay> createState() => _VoiceOverlayState();
}

enum _VoiceStage { listening, result }

class _VoiceOverlayState extends State<VoiceOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _orb;
  _VoiceStage _stage = _VoiceStage.listening;
  String _transcript = '';
  String _reply = '';
  Timer? _autoStop;
  final _rnd = Random();

  static const _fakeTranscripts = [
    'pulse, summarize the last hour',
    'set a sync with the product team tomorrow at 10',
    'draft a follow up for the friday demo',
    'where are we on the rollback?',
  ];

  static const _fakeReplies = [
    'last hour: 3 PRs merged, 1 incident closed, no new alerts.',
    'drafted an invite for 10am. send it?',
    'drafted a friendly follow up. want me to send it?',
    'rollback is flag-gated. ~30s to revert.',
  ];

  @override
  void initState() {
    super.initState();
    _orb = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // TODO(real-stt): replace with platform speech-to-text.
    _autoStop = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _stop();
    });
  }

  void _stop() {
    _autoStop?.cancel();
    setState(() {
      final i = _rnd.nextInt(_fakeTranscripts.length);
      _transcript = _fakeTranscripts[i];
      _reply = _fakeReplies[i];
      _stage = _VoiceStage.result;
    });
  }

  @override
  void dispose() {
    _orb.dispose();
    _autoStop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppPalette.paperDark : AppPalette.paper;
    return Material(
      color: bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: _stage == _VoiceStage.listening ? _listening() : _result(),
        ),
      ),
    );
  }

  Widget _listening() {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? AppPalette.inkOnDark : AppPalette.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.close_rounded, color: ink),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const Spacer(),
        Center(
          child: AnimatedBuilder(
            animation: _orb,
            builder: (context, _) {
              final scale = 0.96 + sin(_orb.value * pi) * 0.06;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dark ? AppPalette.surfaceDark : AppPalette.surface,
                    border: Border.all(
                      color: dark
                          ? AppPalette.hairlineDark
                          : AppPalette.hairline,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ink,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: dark ? AppPalette.ink : Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: Text(
            'talk to pulse',
            style: theme.textTheme.displaySmall,
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'listening…',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppPalette.inkMuted,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Waveform(color: ink, bars: 22),
        const Spacer(),
        Center(
          child: PillButton(
            label: 'stop',
            icon: Icons.stop_rounded,
            onPressed: _stop,
          ),
        ),
      ],
    );
  }

  Widget _result() {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? AppPalette.inkOnDark : AppPalette.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.close_rounded, color: ink),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const Spacer(),
        _Card(
          title: 'you said',
          body: _transcript,
        ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0),
        const SizedBox(height: 12),
        _Card(
          title: 'pulse',
          body: _reply,
          isAi: true,
        ).animate().fadeIn(duration: 240.ms, delay: 80.ms).slideY(begin: 0.04, end: 0),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: 'dismiss',
                variant: PillVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PillButton(
                label: 'send to chat',
                onPressed: () => Navigator.of(context).pop(_transcript),
              ),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String body;
  final bool isAi;
  const _Card({required this.title, required this.body, this.isAi = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppPalette.surfaceDark : AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isAi) ...[
                Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: dark ? AppPalette.inkOnDarkMuted : AppPalette.inkMuted,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: dark ? AppPalette.inkOnDarkMuted : AppPalette.inkMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
