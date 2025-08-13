# UC-02 Keep Up with People

**Origin → App Trigger → Action → Outcome → Signals**

Feed open → `friends_first_header` → tap friend cluster → view story and reply → `friends_first_click`, `story_view`, `inline_reply_send`

## 5Ws
| Who | What | When | Where | Why |
| --- | --- | --- | --- | --- |
| Connected users | Check friends | Daily | Home feed & stories | Stay updated |

## Guardrails
- Flag `triggers.friends_first_header`
- Cap 2/session, 6/day
- Dismiss hides header for session

## Instrumentation checklist
- `friends_first_impression` (proximity_score)
- `friends_first_click` (friend_count)
- `story_view` (tag)
- `inline_reply_send` (share_channel)

## Rollout & rollback
- Ramp by region 10% → 50% → 100%
- Rollback: disable flag and remove cached header
