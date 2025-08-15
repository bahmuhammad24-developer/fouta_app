# Marketplace data

Marketplace screens currently rely on stubbed methods in `MarketplaceService` to provide demo products when the backend is unavailable. This keeps the UI functional even when offline.

## Switching to Firestore
- Replace stub implementations with real Firestore queries/writes.
- `streamProducts` should read from the `products` collection with the same `limit` and filter parameters.
- `getProductById` should fetch a document by ID from Firestore.
- Remove or adjust demo data generators once the backend is wired.

These stubs enable UI development while the backend is built and can be removed once Firestore integration is complete.
