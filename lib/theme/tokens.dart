import 'package:flutter/material.dart';

/// Spacing scale for paddings and margins.
class AppSpacing {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
}

/// Corner radii used across the app.
class AppRadii {
  static const double sm = 8;
  static const double md = 12;
}

/// Standard animation durations.
class AppDurations {
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
}

/// Elevation tokens for surfaces.
class AppElevations {
  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
  static const double level4 = 8;
}

/// Neutral color tokens to avoid direct [Colors] usage.
class AppColors {
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}
