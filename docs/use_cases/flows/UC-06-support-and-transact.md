# UC-06 Support and Transact

**Origin → App Trigger → Action → Outcome → Signals**

Price match → `saved_filter_alert_market` → open listing → complete purchase intent → `alert_impression`, `listing_click`, `purchase_intent`

## 5Ws
| Who | What | When | Where | Why |
| --- | --- | --- | --- | --- |
| Shoppers | Buy items | Price drops | Marketplace alerts | Support creators |

## Guardrails
- Flag `triggers.saved_filter_alert`
- Cap 5/day
- User can mute alerts

## Instrumentation checklist
- `alert_impression` (alert_id, tag)
- `listing_click` (listing_id, position_in_session)
- `purchase_intent` (amount, currency)

## Rollout & rollback
- Ramp: 10% → 50% → 100%
- Rollback: disable flag and clear saved alerts
