import 'dart:math';

import 'package:flutter/material.dart';

class Waveform extends StatefulWidget {
  final Color color;
  final int bars;
  final double height;
  final double barWidth;

  const Waveform({
    super.key,
    this.color = Colors.white,
    this.bars = 28,
    this.height = 60,
    this.barWidth = 4,
  });

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rnd = Random();
  late List<double> _seeds;

  @override
  void initState() {
    super.initState();
    _seeds = List<double>.generate(widget.bars, (_) => _rnd.nextDouble());
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.bars, (i) {
              final phase = (_ctrl.value * 2 * pi) + _seeds[i] * pi * 2;
              final amp = (sin(phase) * 0.5 + 0.5);
              final h = 8 + amp * (widget.height - 12);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.barWidth * 0.4),
                child: Container(
                  width: widget.barWidth,
                  height: h,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(widget.barWidth),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
