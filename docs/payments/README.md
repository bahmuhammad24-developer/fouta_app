
# Payments

This directory tracks payment integration notes.

## Rollout
- Disabled by default via `PAYMENTS_ENABLED` flag.
- Enable with `--dart-define=PAYMENTS_ENABLED=true` after provider review.
- Monitor error rates and transaction logs during staged rollout.
- Roll back by redeploying with flag disabled.

## Security
- No provider keys are bundled while feature is disabled.
- All intents are marked `pending` and contain no sensitive data.
- Review provider OAuth scopes and PCI compliance before enabling.

## PAYMENTS_ENABLED flag
Payments are compile-time flag gated.

Enable at build time:
- Android:
  flutter run --dart-define=PAYMENTS_ENABLED=true
- iOS:
  flutter run --dart-define=PAYMENTS_ENABLED=true

## Service API
MonetizationService.createPurchaseIntent({
  required double amount,
  required String currency,
  required String productId,
  required String createdBy,
})

