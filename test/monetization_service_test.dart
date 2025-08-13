import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/features/monetization/monetization_service.dart';
import 'package:fouta_app/main.dart';

void main() {
  test('intent create and status update', () async {
    final firestore = FakeFirebaseFirestore();
    final service = MonetizationService(firestore: firestore);
    final id = await service.createTipIntent(
      amount: 5,
      currency: 'USD',
      targetUserId: 'seller1',
      createdBy: 'user1',
    );
    final doc = await firestore
        .collection('artifacts')
        .doc(APP_ID)
        .collection('public')
        .doc('data')
        .collection('monetization')
        .doc('intents')
        .collection('items')
        .doc(id)
        .get();
    expect(doc.data()?['type'], 'tip');
    await service.markIntentStatus(id, 'completed');
    final updated = await doc.reference.get();
    expect(updated.data()?['status'], 'completed');
  });
}
