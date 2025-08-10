import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const primary = Color(0xFF7ED6A0); // pastel green
    const secondary = Color(0xFFF5D98B); // pastel gold
    const tertiary = Color(0xFF2D3A8C); // deep indigo
    const coral = Color(0xFFE85A5A); // coral red

    final scheme = const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.black,
      secondary: secondary,
      onSecondary: Colors.black,
      tertiary: tertiary,
      onTertiary: Colors.white,
      error: coral,
      onError: Colors.white,
      background: Color(0xFFF7F9F8),
      onBackground: Color(0xFF0D1215),
      surface: Colors.white,
      onSurface: Color(0xFF111418),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      navigationBarTheme: NavigationBarThemeData(
        // We handle the glow/gradient in selectedIcon; disable the default pill.
        indicatorColor: Colors.transparent,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          return IconThemeData(size: states.contains(MaterialState.selected) ? 28 : 26);
        }),
        labelTextStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  static ThemeData dark() {
    const primary = Color(0xFF3BAF7C);  // emerald
    const secondary = Color(0xFFE1C376); // gold
    const tertiary = Color(0xFF8791C5);  // muted indigo
    const coral = Color(0xFFE2726E);     // coral

    final scheme = const ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.black,
      secondary: secondary,
      onSecondary: Color(0xFF1E1800),
      tertiary: tertiary,
      onTertiary: Color(0xFF0B1024),
      error: coral,
      onError: Colors.black,
      background: Color(0xFF0B1A20), // deep teal/indigo background
      onBackground: Color(0xFFE6ECEF),
      surface: Color(0xFF0F2233),
      onSurface: Color(0xFFE4E8EA),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      navigationBarTheme: const NavigationBarThemeData(
        indicatorColor: Colors.transparent,
      ),
    );
  }
}

