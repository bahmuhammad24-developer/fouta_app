# Monetization Types (Do Not Duplicate)
- Keep a single provider interface: `IPaymentProvider`.
- Keep a single noop provider: `NoopPaymentProvider`.
- `MonetizationService` should accept an optional `IPaymentProvider` in its constructor and default to `NoopPaymentProvider`.
- Do not define `DefaultNoopPaymentProvider` or duplicate `IPaymentProvider` elsewhere in the file.

