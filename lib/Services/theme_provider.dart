import 'package:flutter/material.dart';

/// A ChangeNotifier that holds the current theme mode (light or dark)
/// and allows setting it based on a provided boolean. Consumers can watch
/// [isDarkMode] and rebuild accordingly.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  /// Sets the theme based on the provided [value].
  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }
}
