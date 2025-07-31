import 'package:flutter/material.dart';

/// Defines the central theme for the Fouta application.
///
/// This class consolidates all colour, typography, shape, and spacing values
/// into a pair of [ThemeData] objects for light and dark modes. The values
/// reflect the "Minimalist nature" concept adopted in the July 2025 design
/// update. See the design brief for guidance on usage and ratios.
class FoutaTheme {
  // Core colour tokens
  static const Color primaryColor = Color(0xFF2D5A2D); // Forest green
  static const Color accentColor = Color(0xFFF7B731); // Accent gold
  static const Color backgroundColor = Color(0xFFF2F0E6); // Alabaster
  static const Color surfaceColor = Colors.white; // Surface white for cards
  static const Color errorColor = Color(0xFFD9534F); // Error red
  static const Color onPrimaryColor = Colors.white;
  static const Color onSecondaryColor = Colors.black;
  static const Color textColor = Color(0xFF333333);
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;

  /// Returns the light [ThemeData] configured for Fouta.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: onPrimaryColor,
        onSecondary: onSecondaryColor,
        onSurface: textColor,
        onBackground: textColor,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: primaryColor,
        elevation: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: surfaceColor,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
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
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      textTheme: const TextTheme(
        // Corresponds to the display style in the design brief
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
        // Corresponds to headline style
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
        // Body text
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textColor),
        // Caption text
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: textColor),
      ),
      iconTheme: const IconThemeData(color: textColor, size: 24),
      // CardTheme is omitted because custom FoutaCard widget handles card styling.
    );
  }

  /// Returns the dark [ThemeData] configured for Fouta.
  static ThemeData get darkTheme {
    // Dark mode colours based on Minimalist nature palette
    const Color darkBackground = Color(0xFF1A1A1A);
    const Color darkSurface = Color(0xFF2D2D2D);
    const Color darkText = Color(0xFFE5E5E5);
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        background: darkBackground,
        surface: darkSurface,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: darkText,
        onBackground: darkText,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: accentColor,
        elevation: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: darkSurface,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
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
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkText),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkText),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: darkText),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: darkText),
      ),
      iconTheme: const IconThemeData(color: darkText, size: 24),
      // CardTheme is omitted because custom FoutaCard widget handles card styling.
    );
  }
}