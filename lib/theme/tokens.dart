import 'package:flutter/material.dart';

/// Color tokens for brand and statuses.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0066FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF1B873F);
  static const Color warning = Color(0xFFFFB300);
  static const Color danger = Color(0xFFD32F2F);

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}

/// Spacing scale for paddings and margins.
class AppSpacing {
  AppSpacing._();

  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s7 = 28;
  static const double s8 = 32;
}

/// Corner radii used across the app.
class AppRadii {
  AppRadii._();

  static const double sm = 4;
  static const double md = 8;
  static const double lg = 16;
}

/// Elevation tokens for surfaces.
class AppElevations {
  AppElevations._();

  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
  static const double level4 = 8;
}

/// Accessible text styles for common use cases.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: Colors.black54,
  );
}

