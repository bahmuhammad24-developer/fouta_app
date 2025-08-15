# Product Roadmap

## Phase 0 — Foundation
### Objectives
- Freeze scope of MVP features; document use-case flows end to end.
- Introduce a cohesive design system and accessibility baseline.
- Remove or flag experimental features not supporting the core flow.

### Deliverables
- Use-case flow map (onboarding → discover → create → transact → share → support).
- Information architecture: navigation model, primary/secondary actions, empty-state strategy.
- Design system v1: tokens, grids, spacing, typographic scale, color roles, iconography, elevation, motion primitives, components inventory.
- Accessibility baseline: color contrast, hit-targets, focus order, semantics, reduced motion.

### Success
- First-time user completes onboarding, discovers content, creates and sells once, and shares referral.

## Phase 1 — UX/UI Modernization
### Objectives
- Visual refresh aligned to the use-case flow.
- Component library built for speed and consistency.

### Deliverables
- Navigation model: bottom nav (Home, Marketplace, Create, Messages, Profile) with contextual FABs.
- Home/feed: clean card patterns, consistent media aspect ratios, guarded rollouts via flags.
- Marketplace: list and detail with clear CTAs; "Start Selling" path; progressive disclosure.
- Create flows: stepper forms with inline validation; media pickers with upload feedback.
- Messages: simplified composer, stable message bubble typography, attachment affordances.
- Profile: seller card, social proof, monetization entry points when enabled.
- Error/empty states for every top-level screen.

### Success
- Task success rate ≥ 90% on five key flows.
- System Usability Scale ≥ 80.
- Drop-offs reduced by ≥ 20%.

## Phase 2 — Trust, Safety, and Performance (parallel)
### Objectives
- Strengthen safety rails.
- Keep p95 latencies and egress within budgets.

### Deliverables
- Content moderation pipeline: safety checks pre-publish, report/appeal, abuse throttling.
- Privacy controls: visibility scopes, block/mute, export/delete data flows.
- Performance: paginated/indexed queries; image/thumb pipeline; skeleton loading; cache policy.

### Success
- < 1% content rejections falsely flagged.
- p95 < 800 ms.
- Storage and egress growth ≤ 20% MoM.

## Phase 3 — Pre-Ship Polish
### Objectives
- Remove experimental flags not shipping; lock design tokens; fix copy; finalize telemetry.

### Deliverables
- Design QA: spacing, alignment, icons; dark mode; high-contrast theme.
- Motion polish: micro-interactions respecting reduced-motion.
- Copy: tone guide; empty/error/helper text; localization scaffolding.
- Release criteria: bug bar, rollout plan, observability dashboards.

### Success
- Zero P0/P1 bugs.
- Green release checklist.
- Play-store ready builds.

## Metrics
- **Activation:** time to first creation/sale, K-factor via referrals.
- **Retention:** D1/D7/D30, stickiness (DAU/MAU).
- **Quality:** error rate, app-not-responding, crash-free sessions.
- **Commerce:** conversion to purchase/tip, average order value.
- **Safety:** reports per MAU, action latency, appeals upheld.

