import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme/colors.dart';

class PresenceDot extends StatelessWidget {
  final Presence presence;
  final double size;
  final bool withRing;

  const PresenceDot({
    super.key,
    required this.presence,
    this.size = 10,
    this.withRing = true,
  });

  @override
  Widget build(BuildContext context) {
    if (presence == Presence.offline) {
      // Don't draw anything when offline — silence is its own signal and
      // keeps the avatar clean.
      return const SizedBox.shrink();
    }
    final color = presence == Presence.online
        ? AppPalette.presence
        : AppPalette.presenceIdle;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: withRing ? Border.all(color: bg, width: 2) : null,
      ),
    );
  }
}
