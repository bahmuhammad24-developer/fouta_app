import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/composer_v2/scheduling_service.dart';

void main() {
  test('schedule and cancel post', () async {
    final firestore = FakeFirebaseFirestore();
    final service = SchedulingService(firestore: firestore);
    final publishAt = DateTime(2025);
    await service.schedulePost('u1', 's1', publishAt, {'content': 'hi'});
    var scheduled = await service.listScheduled('u1');
    expect(scheduled.length, 1);
    expect(scheduled.first['payload']['content'], 'hi');
    await service.cancelSchedule('u1', 's1');
    scheduled = await service.listScheduled('u1');
    expect(scheduled, isEmpty);
  });
}
