import 'package:flutter/material.dart';

/// Paper palette. Black-and-white but never harsh #000/#FFF — both ends
/// are softened so the eye doesn't strain. One desaturated sage carries
/// the online-presence signal so it stays functional without color noise.
class AppPalette {
  AppPalette._();

  // ─── Brand ──────────────────────────────────────────────────────────────
  // Terracotta is the brand accent — warm and confident on the cream base.
  // Used for active states, unread, primary CTAs.
  static const brand = Color(0xFFC4703F);
  static const brandLight = Color(0xFFE8A87C);
  static const brandSoft = Color(0xFFF6E4D5);
  static const brandSoftDark = Color(0xFF3D2A1F);

  // Backgrounds: warm sand cream. The whole surface tells you this isn't
  // another off-white productivity app. Dark mode mirrors with a warm,
  // deep "candlelight" feel rather than a cold pure dark.
  static const paper = Color(0xFFF4ECDB);
  static const surface = Color(0xFFFBF5E8);
  static const paperDark = Color(0xFF14100F);
  static const surfaceDark = Color(0xFF1F1B1A);

  // Ink: deep aubergine — softer than black, rich on cream.
  static const ink = Color(0xFF2B1F2D);
  static const inkMuted = Color(0xFF6F5D67);
  static const inkLight = Color(0xFFA89AA0);

  // Ink on dark surfaces
  static const inkOnDark = Color(0xFFF4ECDB);
  static const inkOnDarkMuted = Color(0xFFB0A89D);

  // Edges
  static const hairline = Color(0xFFE2D5C0);
  static const hairlineDark = Color(0xFF2E2826);

  // Bubbles — sent bubbles wear the brand color so your voice = the
  // identity. iMessage-blue principle, tuned warm.
  static const bubbleSelf = brand;
  static const bubbleSelfText = Color(0xFFFFFFFF);
  static const bubbleOther = Color(0xFFEFE5D0); // slightly darker cream
  static const bubbleOtherDark = Color(0xFF262120);

  // Unread / "new" signal — brand terracotta.
  static const unread = brand;

  // Functional micro-pops. All highly desaturated so they read as meaning,
  // not decoration.
  static const presence = Color(0xFF7DA88F); // online
  static const presenceIdle = Color(0xFFC9B98A); // idle
  static const ai = Color(0xFF6F7BA8); // anything from Pulse / AI
  static const aiSoft = Color(0xFFE8EAF3); // tinted fill for AI surfaces
  static const aiSoftDark = Color(0xFF2A2D38);
  static const decision = Color(0xFFB58A40); // pinned / "kept"
  static const decisionSoft = Color(0xFFF3EBD8);
  static const decisionSoftDark = Color(0xFF3A3325);

  /// Desaturated hues used to tint group-chat author names. All sit close to
  /// inkMuted in luminance so they read as variations of the same voice rather
  /// than separate colors.
  static const memberHues = <Color>[
    Color(0xFF5E6A86),
    Color(0xFF6B6B7E),
    Color(0xFF6E5F5B),
    Color(0xFF5E7468),
    Color(0xFF6C5E7A),
    Color(0xFF7A6C58),
    Color(0xFF587A7A),
    Color(0xFF7A5870),
  ];

  /// Deterministic member-tint from a string id (usually a userId).
  static Color hueForMember(String id) {
    if (id.isEmpty) return memberHues.first;
    var hash = 0;
    for (final c in id.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return memberHues[hash % memberHues.length];
  }

  // ─── Editorial accents (used only in special moments) ───────────────────
  // Teal — Privacy Promise screen, Briefing header. Deep, trustworthy.
  static const teal = Color(0xFF0A2E35);
  static const tealLight = Color(0xFF1A4A52);
  static const tealAccent = Color(0xFF2DD4A8);

  // Terracotta + cream — empty states, editorial moments.
  static const terracotta = Color(0xFFC4703F);
  static const terracottaLight = Color(0xFFE8A87C);
  static const cream = Color(0xFFF5F0E8);

  // Functional reds for market down-moves (Briefing).
  static const downTrend = Color(0xFFB04A4A);

  // Soft shadow — short, gentle, never punchy
  static const softShadow = [
    BoxShadow(
      color: Color(0x0F1C1B1A),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}
