# UC-04 Discover and Learn

**Origin → App Trigger → Action → Outcome → Signals**

Search focus → `query_suggestions_search` → tap suggestion → hashtag panel opens → `suggestion_click`, `hashtag_panel_open`, `hashtag_follow`

## 5Ws
| Who | What | When | Where | Why |
| --- | --- | --- | --- | --- |
| Curious users | Explore topics | When searching | Search surface | Learn new things |

## Guardrails
- Flag `triggers.query_suggestions`
- Unlimited per session
- Users can dismiss suggestions

## Instrumentation checklist
- `suggestion_impression` (position)
- `suggestion_click` (query)
- `hashtag_panel_open` (tag)
- `hashtag_follow` (tag)

## Rollout & rollback
- Ramp: 10% → 50% → 100%
- Rollback: disable flag and clear suggestion cache
