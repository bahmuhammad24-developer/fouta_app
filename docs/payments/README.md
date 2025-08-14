# Payments Overview

## Security Checklist
- [ ] Keep provider interfaces free of API keys or card data
- [ ] Enforce HTTPS for all payment-related network calls
- [ ] Store intents only in Firestore until PCI-compliant provider is approved
- [ ] Audit access to monetization collections

## Rollout Plan
1. Land `PAYMENTS_ENABLED` flag defaulting to `false`
2. Merge monetization scaffold and verify intents in Firestore only
3. Gradually enable flag for internal testers
4. Integrate real provider after security and compliance review
5. Monitor latency (<800 ms p95) and storage/egress budgets (<20 % MoM)
6. Roll back by disabling the flag and removing UI if issues arise
