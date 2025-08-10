import 'package:flutter/material.dart';

class AppTheme {
  // Light stays aligned with the current palette
  static ThemeData light() {
    const primary = Color(0xFF7ED6A0); // pastel green
    const secondary = Color(0xFFF5D98B); // pastel gold
    const tertiary = Color(0xFF2D3A8C); // deep indigo
    const coral = Color(0xFFE85A5A); // coral

    final scheme = const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.black,
      secondary: secondary,
      onSecondary: Colors.black,
      tertiary: tertiary,
      onTertiary: Colors.white,
      error: coral,
      onError: Colors.black,
      background: Color(0xFFF7F9F8),
      onBackground: Color(0xFF111418),
      surface: Colors.white,
      onSurface: Color(0xFF111418),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      canvasColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
      dialogTheme: const DialogThemeData(surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(surfaceTintColor: Colors.transparent),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: Colors.transparent, // keep custom glow/animation
      ),
    );
  }

  // Dark: deep teal backgrounds + emerald/gold accents; remove blue-ish tint
  static ThemeData dark() {
    const primary = Color(0xFF3BAF7C); // emerald
    const secondary = Color(0xFFE1C376); // gold
    const tertiary = Color(0xFF8791C5); // muted indigo (subtle accent)
    const coral = Color(0xFFE2726E); // coral

    final scheme = const ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.black,
      secondary: secondary,
      onSecondary: Color(0xFF1E1800),
      tertiary: tertiary,
      onTertiary: Color(0xFF0B1024),
      error: coral,
      onError: Colors.black,
      background: Color(0xFF0E1512), // deep teal, not blue
      onBackground: Color(0xFFE6ECEF),
      surface: Color(0xFF101D15), // slightly lighter than background
      onSurface: Color(0xFFE4E8EA),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      canvasColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
      dialogTheme: const DialogThemeData(surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(surfaceTintColor: Colors.transparent),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: Colors.transparent, // keeps the nice glow animation you liked
      ),
    );
  }
}

