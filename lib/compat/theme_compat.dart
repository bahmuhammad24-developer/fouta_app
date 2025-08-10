import 'package:flutter/material.dart';

/// Backwards-compatible theme helpers.
///
/// These lightweight aliases map old theme access patterns to the
/// Material 3 [ColorScheme] so that existing imports continue to
/// compile without relying on legacy global constants.
class ThemeCompat {
  /// Returns the primary color from the current [ColorScheme].
  static Color primaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// Returns the secondary color from the current [ColorScheme].
  static Color secondaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
}

/// Legacy helper matching the old `kPrimaryColor` constant.
Color kPrimaryColor(BuildContext context) =>
    Theme.of(context).colorScheme.primary;
