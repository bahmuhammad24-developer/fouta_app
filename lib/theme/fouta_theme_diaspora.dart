import 'package:flutter/material.dart';

/// Defines the theme for the "Diaspora Connection" update.
///
/// This theme builds on the original Minimalist nature palette but introduces
/// lighter, more airy tones for light mode and deeper greens and indigo
/// accents for dark mode.  It is designed to accompany the community‑centred
/// redesign by emphasising warmth, openness and cultural richness.  See the
/// design specification for details on how these colours and shapes should be
/// used across the app.
class FoutaThemeDiaspora {
  // Core colours for the Diaspora palette
  static const Color lightPrimary = Color(0xFF3C7548); // softer green
  static const Color lightSecondary = Color(0xFFF4D87B); // soft gold
  static const Color lightBackground = Color(0xFFF7F5EF); // light alabaster
  static const Color lightSurface = Colors.white;
  static const Color lightError = Color(0xFFD9534F);

  static const Color darkPrimary = Color(0xFF2A4930); // deep green
  static const Color darkSecondary = Color(0xFFB38A40); // muted gold
  static const Color darkBackground = Color(0xFF1F2620); // near‑black green
  static const Color darkSurface = Color(0xFF2D362D);
  static const Color darkError = Color(0xFFD9534F);
  static const Color darkText = Color(0xFFE5E5E5);

  static const double cardRadius = 12.0;
  static const double buttonRadius = 10.0;

  /// Returns the light [ThemeData] for the Diaspora palette.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: lightPrimary,
        brightness: Brightness.light,
      ).copyWith(
        secondary: lightSecondary,
        onSecondary: Colors.black,
        surface: lightSurface,
        background: lightBackground,
        error: lightError,
        onSurface: const Color(0xFF333333),
        onBackground: const Color(0xFF333333),
        onPrimary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: Color(0xFF333333),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightSecondary,
        foregroundColor: Colors.black,
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: lightSurface,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightSecondary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: lightPrimary, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Color(0xFF333333)),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF333333)),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF333333), size: 24),
    );
  }

  /// Returns the dark [ThemeData] for the Diaspora palette.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimary,
        brightness: Brightness.dark,
      ).copyWith(
        secondary: darkSecondary,
        onSecondary: Colors.black,
        background: darkBackground,
        surface: darkSurface,
        error: darkError,
        onSurface: darkText,
        onBackground: darkText,
        onPrimary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkSecondary,
        foregroundColor: Colors.black,
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: darkSurface,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkSecondary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: darkPrimary, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkText),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkText),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: darkText),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: darkText),
      ),
      iconTheme: IconThemeData(color: darkText, size: 24),
    );
  }
}