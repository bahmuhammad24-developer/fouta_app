import 'package:flutter/material.dart';

class AppTheme {
  // Light color scheme based on Baobab palette
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: Color(0xFF1D2F28),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFFCCB57B),
      onSecondary: Color(0xFF1E1600),
      background: Color(0xFFFAFBF8),
      onBackground: Color(0xFF111814),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF111814),
      error: Color(0xFFE2726E),
      onError: Color(0xFF000000),
      outline: Color(0xFFD7DFDA),
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
      bottomSheetTheme:
          const BottomSheetThemeData(surfaceTintColor: Colors.transparent),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: Colors.transparent, // keep custom glow/animation
      ),
    );
  }

  // Dark color scheme based on Baobab palette
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: Color(0xFFCCB57B),
      onPrimary: Color(0xFF1E1600),
      secondary: Color(0xFF1D2F28),
      onSecondary: Color(0xFFE6ECE8),
      background: Color(0xFF162019),
      onBackground: Color(0xFFE6ECE8),
      surface: Color(0xFF101A15),
      onSurface: Color(0xFFE6ECE8),
      error: Color(0xFFE2726E),
      onError: Color(0xFF000000),
      outline: Color(0xFF34433D),
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
      bottomSheetTheme:
          const BottomSheetThemeData(surfaceTintColor: Colors.transparent),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: Colors.transparent, // keeps the nice glow animation
      ),
    );
  }
}

