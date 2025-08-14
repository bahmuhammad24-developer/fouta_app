# Cloud Functions

- `src/schedulePosts.ts` publishes scheduled posts when `SCHEDULED_POSTS_ENABLED` is true and logs rejections to `moderation`.
- `src/safetyRules.ts` validates media URLs, text length, and banned words.
