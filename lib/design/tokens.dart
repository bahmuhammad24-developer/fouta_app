import 'package:flutter/material.dart';

enum FTier { t1, t2, t3 }

class FColors {
  FColors._();

  static const _surfaceLight = Color(0xFFFFFFFF);
  static const _surfaceDark = Color(0xFF121212);
  static const _surfaceAltLight = Color(0xFFF5F5F5);
  static const _surfaceAltDark = Color(0xFF1E1E1E);
  static const _textPrimaryLight = Color(0xFF000000);
  static const _textPrimaryDark = Color(0xFFFFFFFF);
  static const _textSecondaryLight = Color(0xFF666666);
  static const _textSecondaryDark = Color(0xFFCCCCCC);
  static const _brandLight = Color(0xFF0066FF);
  static const _brandDark = Color(0xFF6FA8FF);
  static const _successLight = Color(0xFF1B873F);
  static const _successDark = Color(0xFF4CAF50);
  static const _warningLight = Color(0xFFFFB300);
  static const _warningDark = Color(0xFFFFD54F);
  static const _dangerLight = Color(0xFFD32F2F);
  static const _dangerDark = Color(0xFFEF5350);

  static Color surface(Brightness b) =>
      b == Brightness.dark ? _surfaceDark : _surfaceLight;

  static Color surfaceAlt(Brightness b) =>
      b == Brightness.dark ? _surfaceAltDark : _surfaceAltLight;

  static Color textPrimary(Brightness b) =>
      b == Brightness.dark ? _textPrimaryDark : _textPrimaryLight;

  static Color textSecondary(Brightness b) =>
      b == Brightness.dark ? _textSecondaryDark : _textSecondaryLight;

  static Color brand(Brightness b) =>
      b == Brightness.dark ? _brandDark : _brandLight;

  static Color success(Brightness b) =>
      b == Brightness.dark ? _successDark : _successLight;

  static Color warning(Brightness b) =>
      b == Brightness.dark ? _warningDark : _warningLight;

  static Color danger(Brightness b) =>
      b == Brightness.dark ? _dangerDark : _dangerLight;
}

class FSpacing {
  FSpacing._();
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s7 = 28;
  static const double s8 = 32;
}

class FRadius {
  FRadius._();
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 16;
  static const double x2l = 32;
}

class FElevation {
  FElevation._();
  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
  static const double level4 = 8;
}

class FTypography {
  FTypography._();
  static const TextStyle title =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  static const TextStyle body = TextStyle(fontSize: 16);
  static const TextStyle label =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
}
