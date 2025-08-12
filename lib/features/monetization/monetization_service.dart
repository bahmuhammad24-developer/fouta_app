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

  Future<bool> purchaseProduct(String productId) async {
    // TODO: integrate real payment gateway pending security review.
    return purchase(productId);
  }

  Future<bool> subscribeToCreator(String creatorId) async {
    // TODO: handle recurring subscription payments securely.
    return purchase('sub-$creatorId');
  }

  Future<bool> tipCreator(String creatorId, int amountCents) async {
    // TODO: implement tipping once payment integration is approved.
    return purchase('tip-$creatorId-$amountCents');
  }

  /// Whether the given [productId] has been purchased in this session.
  bool hasPurchased(String productId) => _purchases.contains(productId);
}
