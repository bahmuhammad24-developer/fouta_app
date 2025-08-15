# Safety Pipeline

Server-side scheduled posts run through a minimal safety check before publishing.

- `checkSafetyRules` validates text length, forbidden terms, and that media URLs are HTTPS.
- `schedulePosts` runs when `SCHEDULED_POSTS_ENABLED=true`.
  - Passing posts are written to `artifacts/${APP_ID}/public/data/posts`.
  - Rejected posts are written to `artifacts/${APP_ID}/public/data/moderation/scheduled/<id>` with the failure reason and creator info.
