import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

ThemeData buildLightTheme() {
  final text = buildTextTheme(dark: false);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppPalette.paper,
    canvasColor: AppPalette.paper,
    dividerColor: AppPalette.hairline,
    colorScheme: const ColorScheme.light(
      primary: AppPalette.ink,
      onPrimary: Colors.white,
      secondary: AppPalette.ink,
      onSecondary: Colors.white,
      tertiary: AppPalette.inkMuted,
      onTertiary: Colors.white,
      surface: AppPalette.paper,
      onSurface: AppPalette.ink,
      surfaceContainerHighest: AppPalette.surface,
      error: Color(0xFF8B3A3A),
      onError: Colors.white,
    ),
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.paper,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppPalette.ink),
      titleTextStyle: text.titleLarge,
    ),
    iconTheme: const IconThemeData(color: AppPalette.ink),
    splashColor: AppPalette.ink.withValues(alpha: 0.06),
    highlightColor: AppPalette.ink.withValues(alpha: 0.04),
  );
}

ThemeData buildDarkTheme() {
  final text = buildTextTheme(dark: true);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppPalette.paperDark,
    canvasColor: AppPalette.paperDark,
    dividerColor: AppPalette.hairlineDark,
    colorScheme: const ColorScheme.dark(
      primary: AppPalette.inkOnDark,
      onPrimary: AppPalette.ink,
      secondary: AppPalette.inkOnDark,
      onSecondary: AppPalette.ink,
      tertiary: AppPalette.inkOnDarkMuted,
      onTertiary: AppPalette.ink,
      surface: AppPalette.paperDark,
      onSurface: AppPalette.inkOnDark,
      surfaceContainerHighest: AppPalette.surfaceDark,
      error: Color(0xFFE0A5A5),
      onError: AppPalette.ink,
    ),
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.paperDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppPalette.inkOnDark),
      titleTextStyle: text.titleLarge,
    ),
    iconTheme: const IconThemeData(color: AppPalette.inkOnDark),
  );
}
