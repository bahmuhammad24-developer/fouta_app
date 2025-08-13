# UC-03 Express Identity

**Origin → App Trigger → Action → Outcome → Signals**

Composer open → `template_suggestion_composer` → pick template and craft post → publish personal content → `template_use`, `post_publish`

## 5Ws
| Who | What | When | Where | Why |
| --- | --- | --- | --- | --- |
| Creators | Share perspective | Drafting time | Composer | Showcase self |

## Guardrails
- Flag `triggers.template_suggestion`
- Cap 2/session, 4/day
- User can ignore suggestion

## Instrumentation checklist
- `template_suggestion_impression` (tag)
- `template_use` (template_id)
- `post_publish` (media_count)

## Rollout & rollback
- Ramp: 5% → 25% → 100%
- Rollback: disable flag and purge templates
