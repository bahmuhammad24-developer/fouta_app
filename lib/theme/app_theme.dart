import 'package:flutter/material.dart';
import 'tokens.dart';

/// Centralised theme configuration using Material 3.
class AppTheme {
  // Brand colours
  static const Color _primary = Color(0xFF3C7548);
  static const Color _secondary = Color(0xFFF4D87B);
  static const Color _error = Color(0xFFD9534F);

  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: _primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: _primary,
    secondary: _secondary,
    error: _error,
    background: const Color(0xFFF7F5EF),
    surface: AppColors.white,
    onPrimary: AppColors.white,
    onSecondary: AppColors.black,
    onBackground: const Color(0xFF333333),
    onSurface: const Color(0xFF333333),
  );

  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: _primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFF2A4930),
    secondary: const Color(0xFFB38A40),
    error: _error,
    background: const Color(0xFF1F2620),
    surface: const Color(0xFF2D362D),
    onPrimary: AppColors.white,
    onSecondary: AppColors.black,
    onBackground: const Color(0xFFE5E5E5),
    onSurface: const Color(0xFFE5E5E5),
  );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: lightColorScheme.background,
      fontFamily: 'Inter',
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: darkColorScheme.background,
      fontFamily: 'Inter',
    );
  }
}
