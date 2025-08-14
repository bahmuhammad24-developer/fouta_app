# Monetization Types (Do Not Duplicate)

- Keep a single provider interface: `IPaymentProvider`.
- Keep a single noop provider: `NoopPaymentProvider`.
- `MonetizationService` must receive an optional `IPaymentProvider` and default to `NoopPaymentProvider`.
- Do not add `DefaultNoopPaymentProvider` or duplicate `IPaymentProvider` elsewhere in the file.

