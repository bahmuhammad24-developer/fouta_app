# UC-05 Belong and Coordinate

**Origin → App Trigger → Action → Outcome → Signals**

Group open → `group_rules_pinned` → acknowledge rules → invite friend to event via DM → `rules_view`, `rule_acknowledge`, `invite_sent`

## 5Ws
| Who | What | When | Where | Why |
| --- | --- | --- | --- | --- |
| Community members | Align on norms | Joining groups | Group page | Coordinate activity |

## Guardrails
- Flag `triggers.group_rules`
- 1 per group/day
- Dismiss after acknowledge

## Instrumentation checklist
- `rules_view` (group_id)
- `rule_acknowledge` (group_id)
- `invite_sent` (event_id, share_channel)

## Rollout & rollback
- Ramp: 5% → 25% → 100%
- Rollback: disable flag and remove pinned panel
