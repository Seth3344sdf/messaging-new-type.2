import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/avatar_library.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';

/// Resolves an avatarId to a spec via AppState. If nothing matches, falls
/// back to a quiet "··" placeholder.
class AvatarView extends StatelessWidget {
  final String avatarId;
  final double size;
  final bool selected;

  const AvatarView({
    super.key,
    required this.avatarId,
    this.size = 40,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final spec = app.avatarLookup[avatarId] ??
        AvatarLibrary.custom(id: avatarId, initials: '··', tone: PaperTone.paper);
    return AvatarSpecView(spec: spec, size: size, selected: selected);
  }
}

class AvatarSpecView extends StatelessWidget {
  final AvatarSpec spec;
  final double size;
  final bool selected;

  const AvatarSpecView({
    super.key,
    required this.spec,
    this.size = 40,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = spec.tone.background(dark);
    final fg = spec.tone.stroke(dark);
    final hairline = dark ? AppPalette.hairlineDark : AppPalette.hairline;

    // Initials scale with the circle so they look balanced at every size.
    final fontSize = size * 0.40;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: fg, width: 2)
            : Border.all(color: hairline, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        spec.initials,
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          height: 1.0,
        ),
      ),
    );
  }
}
