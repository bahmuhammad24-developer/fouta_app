import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/analytics/analytics_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class _FakeFirebaseAnalytics implements FirebaseAnalytics {
  final List<String> events = [];
  @override
  Future<void> logEvent({required String name, Map<String, Object?>? parameters}) async {
    events.add(name);
  }
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('respects opt-out', () async {
    final fake = _FakeFirebaseAnalytics();
    final service = AnalyticsService(analytics: fake);
    await service.init();
    await service.setEnabled(false);
    await service.logEvent('test');
    expect(fake.events.isEmpty, true);
    await service.setEnabled(true);
    await service.logEvent('test');
    expect(fake.events.length, 1);
  });
}
