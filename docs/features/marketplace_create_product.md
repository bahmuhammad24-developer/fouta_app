# Create Product (Scaffold)

- Minimal form with validation (title, price, currency, optional description).
- Uses stubbed MarketplaceService.createProduct(...) returning a synthetic ID.
- Navigation:
  - Marketplace banner "Start Selling" now opens this screen (if present), otherwise an AppBar "Sell" button appears.
- Future work:
  - Image picker and upload to storage.
  - Real Firestore write + security rules.
  - Seller dashboard and listing management.
