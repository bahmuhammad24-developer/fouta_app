import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/analytics/analytics_service.dart';

void main() {
  test('logEvent stores event and emits through stream', () async {
    final service = AnalyticsService();
    final events = <AnalyticsEvent>[];
    service.eventsStream.listen(events.add);

    service.logEvent('login', parameters: {'method': 'email'});
    await Future<void>.delayed(Duration.zero);

    expect(service.events.single.name, 'login');
    expect(events.single.parameters['method'], 'email');
  });
}
