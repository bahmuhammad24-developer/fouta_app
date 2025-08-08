import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// Provides the app's current theme mode (light or dark) and updates it when
/// requested. Widgets can listen to [isDarkMode] for rebuilds.

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadDarkMode();
  }

  Future<void> _loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  /// Sets dark mode to [isDark]. Persists the change and notifies listeners
  /// only when the value changes.
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);

    notifyListeners();
  }
}
