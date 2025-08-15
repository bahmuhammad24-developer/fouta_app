# API Contract

Draft REST/Callable functions.

## POST /challenges.create
Request: `{title, description, tags[], location?, links[]}`
Response: `{id}`

## POST /challenges.vote
Request: `{id, dir: 1|-1|0}`
Response: `{score}`

## POST /challenges.comment
Request: `{id, body}`
Response: `{commentId}`

## GET /challenges.feed
Request: `{mode: 'hot'|'new'|'top'|'rising', tagKeys?, region?, limit?, cursor?}`
Response: `{items[], nextCursor?}`

## POST /challenges.follow
Request: `{id, on: bool}`

## POST /challenges.report
Request: `{id, reason}`

## Error Model
Standard `{code, message}` structure; writes should be idempotent via client IDs or server dedupe.

## Auth Requirements
All write operations require authentication.

## Pagination & Cursors
Composite cursor on `createdAt` and `score` for stable paging.
