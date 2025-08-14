// Payments feature flag (compile-time)
const bool PAYMENTS_ENABLED =
    bool.fromEnvironment('PAYMENTS_ENABLED', defaultValue: false);

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

/// No-op implementation used until real payments are integrated.
class NoopPaymentProvider implements IPaymentProvider {
  String _id(String prefix) => '${prefix}_${DateTime.now().millisecondsSinceEpoch}';

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

class MonetizationService {
  final IPaymentProvider _provider;

  /// Use dependency injection; default to Noop so the app runs without provider keys.
  MonetizationService({IPaymentProvider? provider})
      : _provider = provider ?? NoopPaymentProvider();

  Future<String> createTipIntent({
    required double amount,
    required String currency,
    required String targetUserId,
    required String createdBy,
  }) {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be > 0');
    }
    return _provider.createTip(
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
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be > 0');
    }
    return _provider.createPurchase(
      amount: amount,
      currency: currency,
      productId: productId,
      createdBy: createdBy,
    );
  }

  // Add similar facade methods for subscription as needed using _provider.
}
