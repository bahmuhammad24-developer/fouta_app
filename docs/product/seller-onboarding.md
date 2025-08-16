# Seller Onboarding Flow

The onboarding wizard guides new sellers through three steps:

1. **Profile basics** – display name, location, and contact info.
2. **First product draft** – title, price, and up to three image URLs saved as a draft (`status: draft`).
3. **Review & publish** – validates required fields then marks the draft as `published` and flags onboarding as complete.

Draft data is stored in Firestore under `users/{uid}/meta/onboarding` and `products/{productId}`. Missing required fields during publish surface inline errors and block submission.
