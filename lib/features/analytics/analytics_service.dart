import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper around [FirebaseAnalytics] with simple opt-out capability.
class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;
  bool _enabled = true;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('analytics_enabled') ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_enabled', enabled);
  }

  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
    if (!_enabled) return;
    await _analytics.logEvent(name: name, parameters: parameters);
    final now = DateTime.now().toIso8601String();
    // ignore: avoid_print
    print('[$now][AnalyticsService] logged $name');
  }
}
