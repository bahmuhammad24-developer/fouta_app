# Marketplace UX

## Filters and Sort
- **Filters:** category, price range, location radius (km).
- **Sort:** newest first, price ascending, price descending.
- Preferences persist under `users/{uid}/meta/marketplaceFilters` and update listings live.

## Product Card
- 4:3 image area with shimmer placeholder and broken-image fallback.
- Shows title, price, and seller.
- Favorite button updates optimistically and retries once on failure.

## States
- Loading: grid skeletons matching card layout.
- Empty: message indicating no products for current filters.
