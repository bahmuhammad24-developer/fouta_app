import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/features/monetization/monetization_service.dart';
import 'package:fouta_app/main.dart';

class _TestProvider implements IPaymentProvider {
  @override
  Future<PaymentResult> tip({
    required double amount,
    required String currency,
    required String targetUserId,
    required String createdBy,
  }) async {
    return const PaymentResult(id: 'test-tip', status: 'custom');
  }

  @override
  Future<PaymentResult> subscription({
    required double amount,
    required String currency,
    required String targetUserId,
    required String createdBy,
  }) async {
    return const PaymentResult(id: 'test-sub', status: 'custom');
  }

  @override
  Future<PaymentResult> purchase({
    required double amount,
    required String currency,
    required String productId,
    required String createdBy,
  }) async {
    return const PaymentResult(id: 'test-purchase', status: 'custom');
  }
}

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
    expect(doc.data()?['status'], 'pending');
    await service.markIntentStatus(id, 'completed');
    final updated = await doc.reference.get();
    expect(updated.data()?['status'], 'completed');
  });

  test('custom provider when enabled', () async {
    final firestore = FakeFirebaseFirestore();
    final service = MonetizationService(
      firestore: firestore,
      paymentsEnabled: true,
      provider: _TestProvider(),
    );
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
    expect(doc.data()?['status'], 'custom');
  });
}

