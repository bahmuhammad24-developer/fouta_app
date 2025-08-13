import 'package:cloud_firestore/cloud_firestore.dart';

import '../../main.dart';

/// Records monetization intents for tips, subscriptions, and purchases.
///
/// TODO: Wire a verified payment provider after security review to fulfill
/// intents and securely handle funds.
class MonetizationService {
  MonetizationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
      'status': 'draft',
    });
    return doc.id;
  }

  Future<String> createTipIntent({
    required double amount,
    required String currency,
    required String targetUserId,
    required String createdBy,
  }) {
    return _createIntent(
      type: 'tip',
      amount: amount,
      currency: currency,
      targetUserId: targetUserId,
      createdBy: createdBy,
    );
  }

  Future<String> createSubscriptionIntent({
    required double amount,
    required String currency,
    required String targetUserId,
    required String createdBy,
  }) {
    return _createIntent(
      type: 'subscription',
      amount: amount,
      currency: currency,
      targetUserId: targetUserId,
      createdBy: createdBy,
    );
  }

  Future<String> createPurchaseIntent({
    required double amount,
    required String currency,
    required String productId,
    required String createdBy,
  }) {
    return _createIntent(
      type: 'purchase',
      amount: amount,
      currency: currency,
      productId: productId,
      createdBy: createdBy,
    );
  }

  Future<void> markIntentStatus(String intentId, String status) {
    return _intents.doc(intentId).update({'status': status});
  }
}
