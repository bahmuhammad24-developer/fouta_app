# UC-01 Quick Entertainment

**Origin → App Trigger → Action → Outcome → Signals**

Feed scroll → `next_up_rail` → tap recommended short → next video plays → `video_complete`, `next_up_click`, `session_length_delta`

## 5Ws
| Who | What | When | Where | Why |
| --- | --- | --- | --- | --- |
| Casual scrollers | Watch short videos | Break moments | Shorts feed | Fast fun |

## Guardrails
- Flag `triggers.next_up.enabled`
- Cap 3/session, 8/day
- Dismiss remembers for session

## Instrumentation checklist
- `video_complete` (video_duration, position_in_session)
- `next_up_click` (recommended_id)
- `session_length_delta` (seconds)

## Rollout & rollback
- Ramp: 5% → 50% → 100%
- Rollback: disable flag and clear impression cache
