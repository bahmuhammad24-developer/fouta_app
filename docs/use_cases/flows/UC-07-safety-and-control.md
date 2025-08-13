# UC-07 Safety and Control

**Origin → App Trigger → Action → Outcome → Signals**

Settings open → `tune_your_feed_prompt` → adjust preferences → add muted words → `tune_action`, `muted_word_add`

## 5Ws
| Who | What | When | Where | Why |
| --- | --- | --- | --- | --- |
| Concerned users | Curate feed | After seeing irrelevant content | Settings | Safer experience |

## Guardrails
- Flag `triggers.tune_feed`
- 1 per session
- Opt-out in settings

## Instrumentation checklist
- `tune_feed_prompt` (proximity_score)
- `tune_action` (selected_topic)
- `muted_word_suggestion` (word)
- `muted_word_add` (word)

## Rollout & rollback
- Ramp: 5% → 25% → 100%
- Rollback: disable flag and reset prompt state
