import 'package:flutter/material.dart';

import '../theme/colors.dart';

enum PillVariant { primary, ghost, soft }

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PillVariant variant;
  final bool dense;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = PillVariant.primary,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final dark = Theme.of(context).brightness == Brightness.dark;

    late final Color bg;
    late final Color fg;
    late final Border? border;

    switch (variant) {
      case PillVariant.primary:
        bg = AppPalette.brand;
        fg = Colors.white;
        border = null;
        break;
      case PillVariant.ghost:
        bg = Colors.transparent;
        fg = dark ? AppPalette.inkOnDark : AppPalette.ink;
        border = Border.all(
          color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
        );
        break;
      case PillVariant.soft:
        bg = dark ? AppPalette.surfaceDark : AppPalette.surface;
        fg = dark ? AppPalette.inkOnDark : AppPalette.ink;
        border = Border.all(
          color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
        );
        break;
    }

    final pad = dense
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 9)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 13);

    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: border,
            ),
            child: Padding(
              padding: pad,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: fg, size: 17),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
