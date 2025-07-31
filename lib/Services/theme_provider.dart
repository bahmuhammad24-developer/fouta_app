import 'package:flutter/material.dart';

/// A ChangeNotifier that holds the current theme mode (light or dark)
/// and allows toggling between modes. Consumers can watch [isDarkMode]
/// and rebuild accordingly.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }
}