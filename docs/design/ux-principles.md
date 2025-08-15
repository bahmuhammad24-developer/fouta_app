# UX/UI Principles

## Principles
- **Task-first hierarchy:** primary CTA above fold; secondary actions tucked into overflow.
- **Progressive disclosure:** short paths for frequent actions; deeper menus for advanced.
- **Visual rhythm:** 4/8px spacing grid; line length 45–75 chars; 1.25–1.33 typographic scale.
- **Color system:** semantic roles (Surface/On-Surface/Primary/On-Primary/Warning/Success); ensure 4.5:1 contrast.
- **Motion:** sub-250ms on taps, <400ms for transitions; ease-in/out; disable on reduced motion.
- **States:** default/hover/focus/pressed/disabled for all interactive elements; skeletons + empty states.
- **Input quality:** masked inputs, inline validation, helpful error copy, undo where safe.
- **Safety:** clear report/block affordances; contextual warnings; rate limiting; explainability.

## Interaction & Flow Inventory
- Onboarding: login/signup → permissions → “first task” shortcut; explain value fast.
- Discovery: feed cards; marketplace search/filter/sort; deep links retained on back-nav.
- Creation: simple vs advanced form; autosave drafts; media queue with progress.
- Transact: product detail → add to cart / tip / purchase intent → confirmation → receipts.
- Messaging: composer shortcuts (camera/gallery); retries; offline queue.
- Profile: seller setup checklist; links; badges; monetization toggle.
- Referrals: share code → invite landing → attribution.

## Design System Scope
- All components are organized into a four-tier structure — see [system/tiered-structure.md](system/tiered-structure.md) for definitions and usage.
- **Tokens:** color, typography, spacing, radius, elevation, motion.
- **Components:** AppBar, BottomNav, Tabs, Card, ListTile, Sheet, Dialog, Tooltip, Badge, Chip, Button set, TextFields, Dropdowns, Switch/Checkbox/Radio, Steppers, Toast/SnackBar, Skeleton, Empty-state templates.
- **Layouts:** 4-column (mobile), 8-column (tablet) grids; gutters; safe-area rules.
- **Content:** voice/tone guidelines; message length limits; placeholders; emoji handling.
- **Accessibility:** focus order, semantics labels, large text support, hit-target ≥ 44dp.

