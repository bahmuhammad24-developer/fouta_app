# Moderation Pipeline

Defines the trust and safety flow for content submitted to Fouta.

## Pre-publish Checks
- Automated scans for malware, CSAM, and policy keywords.
- Media sizing and format validation.
- Client-side nudges for potentially sensitive content.

## Queues
- Flagged submissions enter reviewer queues with priority buckets.
- Escalations route to specialized teams for legal or high-risk cases.

## Appeals
- Users can appeal removals from their safety dashboard.
- Appeals track reviewer decisions, timestamps, and reviewer IDs.

## Audit Logging
- All moderation actions append to an immutable log.
- Entries include actor, rationale, target IDs, and before/after states.

## Rate Limits
- Throttle report volume and submission retries to deter spam.
- Exponential backoff resets after successful publishing.

## User Feedback Loops
- Notices explain why content was restricted and reference policy.
- In-product surveys gather satisfaction data on moderation outcomes.
