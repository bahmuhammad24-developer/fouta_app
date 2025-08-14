import 'package:cloud_firestore/cloud_firestore.dart';

import '../../main.dart';
import '../../utils/app_flags.dart';

// == Monetization provider interface ==
abstract class IPaymentProvider {
  Future<String> createTip({
    required double amount,
    required String currency,
    required String targetUserId,
    required String createdBy,
  });

  Future<String> createSubscription({
    required double amount,
    required String currency,
    required String targetUserId,
    required String createdBy,
  });

  Future<String> createPurchase({
    required double amount,
    required String currency,
    required String productId,
    required String createdBy,
  });
}

// == No-op provider used until real payments are enabled ==
class NoopPaymentProvider implements IPaymentProvider {
  String _id(String prefix) =>
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}';

  @override
  Future<String> createTip({
    required double amount,
    required String currency,
    required String targetUserId,
    required String createdBy,
  }) async {
    return _id('noop_tip');
  }

  @override
  Future<String> createSubscription({
    required double amount,
    required String currency,
    required String targetUserId,
    required String createdBy,
  }) async {
    return _id('noop_sub');
  }

  @override
  Future<String> createPurchase({
    required double amount,
    required String currency,
    required String productId,
    required String createdBy,
  }) async {
    return _id('noop_purchase');
  }
}

// == Service ==
class MonetizationService {
  final FirebaseFirestore _firestore;
  final IPaymentProvider _provider;

  // Use DI; default to NoopPaymentProvider so app runs without real keys.
  MonetizationService({
    FirebaseFirestore? firestore,
    IPaymentProvider? provider,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _provider = provider ?? NoopPaymentProvider();

  CollectionReference<Map<String, dynamic>> get _intents => _firestore
      .collection('artifacts')
      .doc(APP_ID)
      .collection('public')
      .doc('data')
      .collection('monetization')
      .doc('intents')
      .collection('items');

  Future<String> _createIntent({
    required String type,
    required double amount,
    required String currency,
    String? targetUserId,
    String? productId,
    required String createdBy,
  }) async {
    final doc = await _intents.add({
      'type': type,
      'amount': amount,
      'currency': currency,
      if (targetUserId != null) 'targetUserId': targetUserId,
      if (productId != null) 'productId': productId,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'status': AppFlags.paymentsEnabled ? 'draft' : 'disabled',
    });
    return doc.id;
  }

  Future<String> createTipIntent({
    required double amount,
    required String currency,
    required String targetUserId,
    required String createdBy,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be > 0');
    }
    final intentId = await _createIntent(
      type: 'tip',
      amount: amount,
      currency: currency,
      targetUserId: targetUserId,
      createdBy: createdBy,
    );
    await _provider.createTip(
      amount: amount,
      currency: currency,
      targetUserId: targetUserId,
      createdBy: createdBy,
    );
    return intentId;
  }

  Future<String> createSubscriptionIntent({
    required double amount,
    required String currency,
    required String targetUserId,
    required String createdBy,
  }) async {
    final intentId = await _createIntent(
      type: 'subscription',
      amount: amount,
      currency: currency,
      targetUserId: targetUserId,
      createdBy: createdBy,
    );
    await _provider.createSubscription(
      amount: amount,
      currency: currency,
      targetUserId: targetUserId,
      createdBy: createdBy,
    );
    return intentId;
  }

  Future<String> createPurchaseIntent({
    required double amount,
    required String currency,
    required String productId,
    required String createdBy,
  }) async {
    final intentId = await _createIntent(
      type: 'purchase',
      amount: amount,
      currency: currency,
      productId: productId,
      createdBy: createdBy,
    );
    await _provider.createPurchase(
      amount: amount,
      currency: currency,
      productId: productId,
      createdBy: createdBy,
    );
    return intentId;
  }

  Future<void> markIntentStatus(String intentId, String status) {
    return _intents.doc(intentId).update({'status': status});
  }
}

