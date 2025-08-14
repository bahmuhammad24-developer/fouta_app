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
