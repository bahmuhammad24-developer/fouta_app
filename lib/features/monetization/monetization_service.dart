/// Placeholder for ads, subscriptions, and marketplace transactions.
import 'dart:async';

/// A naive monetization service that records purchases locally. Real payment
/// processing would integrate with platform-specific providers.
class MonetizationService {
  final Set<String> _purchases = {};

  /// Simulates purchasing an item identified by [productId]. Always succeeds
  /// after a short delay and records the purchase locally.
  Future<bool> purchase(String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _purchases.add(productId);
    return true;
  }

  /// Whether the given [productId] has been purchased in this session.
  bool hasPurchased(String productId) => _purchases.contains(productId);
}
