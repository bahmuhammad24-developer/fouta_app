import 'package:flutter/material.dart';


/// Provides the app's current theme mode (light or dark) and updates it when
/// requested. Widgets can listen to [isDarkMode] for rebuilds.

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;


  /// Sets dark mode to [isDark]. Notifies listeners only when the value changes.
  void setDarkMode(bool isDark) {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;

    notifyListeners();
  }
}
