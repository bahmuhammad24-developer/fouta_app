# Security & Indexes

## Firestore Collections
- `challenges/{id}`
- `challengeComments/{id}` (collection group) or `challenges/{id}/comments/{cid}`
- `challengeVotes/{id}` (collection group) or `challenges/{id}/votes/{uid}`
- `challengeFollows/{id}` (collection group)

## Composite Indexes (Draft)
- `challenges`: where `tagKeys` array-contains/any + orderBy `createdAt` desc
- `challenges`: orderBy `score` desc, filter `createdAtDay` in range (for Top windows)
- `comments`: where `challengeId` == X, orderBy `createdAt` asc

## Storage
- `challenge_media/uid/*` for optional images or video

## Rules Outline
- Create challenge: auth required; size & content validations; `authorId == uid`
- Vote: one vote per user per challenge; server-timestamp write; tally in function
- Comment: auth; length limits; rate limit tokens

## CI Linkage
When implemented, update `firestore.rules`, `storage.rules`, and `firestore.indexes.json` via PR per Firebase automation docs.
