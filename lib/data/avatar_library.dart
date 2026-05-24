import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Four neutral paper tones that work in light and dark mode. Backgrounds
/// stay quiet so the initials carry the identity.
enum PaperTone { paper, warm, cool, ink }

extension PaperToneColors on PaperTone {
  Color background(bool dark) {
    switch (this) {
      case PaperTone.paper:
        return dark ? const Color(0xFF26272B) : const Color(0xFFF1EFE9);
      case PaperTone.warm:
        return dark ? const Color(0xFF2B2825) : const Color(0xFFEAE5DA);
      case PaperTone.cool:
        return dark ? const Color(0xFF24272C) : const Color(0xFFE6E7E3);
      case PaperTone.ink:
        return dark ? const Color(0xFFEDEAE3) : AppPalette.ink;
    }
  }

  Color stroke(bool dark) {
    switch (this) {
      case PaperTone.paper:
      case PaperTone.warm:
      case PaperTone.cool:
        return dark ? const Color(0xFFEDEAE3) : AppPalette.ink;
      case PaperTone.ink:
        return dark ? AppPalette.ink : const Color(0xFFFAF8F1);
    }
  }
}

class AvatarSpec {
  final String id;
  final String initials; // 1–2 characters, uppercase
  final PaperTone tone;
  const AvatarSpec({required this.id, required this.initials, required this.tone});

  AvatarSpec copyWith({String? initials, PaperTone? tone}) => AvatarSpec(
        id: id,
        initials: initials ?? this.initials,
        tone: tone ?? this.tone,
      );
}

class AvatarLibrary {
  AvatarLibrary._();

  /// Two-letter monogram from a person's name.
  /// "Jamie Morales" → "JM"; "Pulse" → "P"; "you" → "YO".
  static String initialsFrom(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '··';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final w = parts.first;
      if (w.length >= 2) {
        return w.substring(0, 2).toUpperCase();
      }
      return w.substring(0, 1).toUpperCase();
    }
    final first = parts.first.characters.first;
    final last = parts.last.characters.first;
    return (first + last).toUpperCase();
  }

  /// Deterministic paper tone from a string seed, so the same name always
  /// gets the same tone across the app.
  static PaperTone toneFor(String seed) {
    final tones = PaperTone.values;
    if (seed.isEmpty) return PaperTone.paper;
    var hash = 0;
    for (final c in seed.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return tones[hash % tones.length];
  }

  static AvatarSpec forUser({
    required String userId,
    required String name,
  }) {
    return AvatarSpec(
      id: 'u:$userId',
      initials: initialsFrom(name),
      tone: toneFor(userId),
    );
  }

  static AvatarSpec custom({
    required String id,
    required String initials,
    required PaperTone tone,
  }) {
    return AvatarSpec(id: id, initials: initials.toUpperCase(), tone: tone);
  }
}
