import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Inter for body and UI. DM Serif Display for editorial moments
/// (Privacy Promise, Briefing headers, Knowledge titles, empty states).
/// Inter handles every other surface.
TextTheme buildTextTheme({required bool dark}) {
  final primary = dark ? AppPalette.inkOnDark : AppPalette.ink;
  final secondary = dark ? AppPalette.inkOnDarkMuted : AppPalette.inkMuted;

  final body = GoogleFonts.interTextTheme().apply(
    bodyColor: primary,
    displayColor: primary,
  );

  // Display sizes use heavier weight + tight tracking. Display Inter
  // (otf "Inter Display") is the variable-axis variant — google_fonts
  // serves it via the Inter family with tight letterSpacing here.
  return body.copyWith(
    displayLarge: GoogleFonts.inter(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      color: primary,
      letterSpacing: -0.8,
      height: 1.05,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: primary,
      letterSpacing: -0.6,
      height: 1.1,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: primary,
      letterSpacing: -0.4,
      height: 1.15,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: -0.25,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: -0.15,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: -0.05,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: primary,
      height: 1.45,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      color: primary,
      height: 1.4,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: secondary,
      letterSpacing: 0.05,
      height: 1.35,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: -0.05,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: secondary,
      letterSpacing: 0.3,
    ),
  );
}

/// Editorial serif headline. Use sparingly — only for moments that should feel
/// like the opening of a story: Privacy Promise, the Pulse greeting, Briefing
/// title, empty-state headlines.
TextStyle serifHeadline({
  required double size,
  Color? color,
  FontWeight weight = FontWeight.w400,
  double letterSpacing = -0.4,
  double height = 1.15,
}) {
  return GoogleFonts.dmSerifDisplay(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}
