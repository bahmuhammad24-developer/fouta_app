import 'package:cloud_firestore/cloud_firestore.dart';

import '../../main.dart';
import '../../utils/app_flags.dart';

/// Payment provider interface ensures sensitive data stays out of the app.
abstract class IPaymentProvider {
  Future<void> fulfillTip(String intentId);
  Future<void> fulfillSubscription(String intentId);
  Future<void> fulfillPurchase(String intentId);
}

/// Default provider used in development; does nothing.
class DefaultNoopPaymentProvider implements IPaymentProvider {
  @override
  Future<void> fulfillTip(String intentId) async {}

  @override
  Future<void> fulfillSubscription(String intentId) async {}

  @override
  Future<void> fulfillPurchase(String intentId) async {}
}

/// Feature flag to toggle payment processing at build time.
const bool PAYMENTS_ENABLED =
    bool.fromEnvironment('PAYMENTS_ENABLED', defaultValue: false);

/// Result from a payment provider when creating an intent.
class PaymentResult {
  const PaymentResult({required this.id, required this.status});

  final String id;
  final String status;
}

/// Interface for payment providers capable of handling different intent types.
abstract class IPaymentProvider {
  Future<PaymentResult> tip({
    required double amount,
    required String currency,
    required String targetUserId,
    required String createdBy,
  });

  Future<PaymentResult> subscription({
    required double amount,
    required String currency,
    required String targetUserId,
    required String createdBy,
  });

  Future<PaymentResult> purchase({
    required double amount,
    required String currency,
    required String productId,
    required String createdBy,
  });
}

/// Placeholder provider that generates synthetic IDs and pending status.
class NoopPaymentProvider implements IPaymentProvider {
  String _id() => 'noop-${DateTime.now().millisecondsSinceEpoch}';

  @override
  Future<PaymentResult> tip({
    required double amount,
    required String currency,
    required String targetUserId,
    required String createdBy,
  }) async {
    return PaymentResult(id: _id(), status: 'pending');
  }

  @override
  Future<PaymentResult> subscription({
    required double amount,
    required String currency,
    required String targetUserId,
    required String createdBy,
  }) async {
    return PaymentResult(id: _id(), status: 'pending');
  }

  @override
  Future<PaymentResult> purchase({
    required double amount,
    required String currency,
    required String productId,
    required String createdBy,
  }) async {
    return PaymentResult(id: _id(), status: 'pending');
  }
}

/// Records monetization intents for tips, subscriptions, and purchases.
///
/// TODO: Wire a verified payment provider after security review to fulfill
/// intents and securely handle funds.
class MonetizationService {

  MonetizationService({
    FirebaseFirestore? firestore,
    IPaymentProvider? provider,
    bool? paymentsEnabled,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _paymentsEnabled = paymentsEnabled ?? PAYMENTS_ENABLED,
        _provider = (paymentsEnabled ?? PAYMENTS_ENABLED)
            ? (provider ?? NoopPaymentProvider())
            : NoopPaymentProvider();

  final FirebaseFirestore _firestore;
  final IPaymentProvider _provider;
  final bool _paymentsEnabled;


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
    final intentId = await _createIntent(
      type: 'tip',
      amount: amount,
      currency: currency,
      targetUserId: targetUserId,
      createdBy: createdBy,
    );
    final result = await _provider.tip(
      amount: amount,
      currency: currency,
      targetUserId: targetUserId,
      createdBy: createdBy,
    );
    await markIntentStatus(intentId, result.status);
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
    final result = await _provider.subscription(
      amount: amount,
      currency: currency,
      targetUserId: targetUserId,
      createdBy: createdBy,
    );
    await markIntentStatus(intentId, result.status);
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
    final result = await _provider.purchase(
      amount: amount,
      currency: currency,
      productId: productId,
      createdBy: createdBy,
    );
    await markIntentStatus(intentId, result.status);
    return intentId;
  }

  Future<void> markIntentStatus(String intentId, String status) {
    return _intents.doc(intentId).update({'status': status});
  }

  Future<void> fulfillTipIntent(String intentId) {
    return _provider.fulfillTip(intentId);
  }

  Future<void> fulfillSubscriptionIntent(String intentId) {
    return _provider.fulfillSubscription(intentId);
  }

  Future<void> fulfillPurchaseIntent(String intentId) {
    return _provider.fulfillPurchase(intentId);
  }
}

