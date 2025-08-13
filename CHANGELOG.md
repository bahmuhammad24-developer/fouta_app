# Changelog

- 2025-08-12 America/New_York – fix(build): resolve trigger/widget API mismatches, nullability, and syntax issues; stabilize imports.


- 2025-08-12 – Fix Shorts widget structure; remove const misuse in Events; stabilize Profile; tighten trending tags state.
- 2025-08-12 – Trigger Orchestrator + Next-Up rail, Keyword filter chips, Friends-first header, Story inline reply chip (flagged). (Committed on fallback branch `work` due to branch creation restrictions.)
- 2025-08-12 – Discovery Ranking V2 (watch-time/DM shares/follows-after-view + 7d decay) and NavBar V2 scaffold, both flagged.
- 2025-08-12 – fix(profile): eliminate flicker by caching streams, distinct setState, and gapless image rendering. (Committed on fallback branch `work` due to branch creation restrictions.)
- 2025-08-12 – Integration Pass 3: focus visuals, textScale guardrails, reduced-motion fallbacks. (Committed on fallback branch `work` due to branch creation restrictions.)
- 2025-08-12 – Integration Pass 2: Hero images, FoutaTransitions in Post/Shorts detail flows. (Committed on fallback branch `work` due to branch creation restrictions.)
- 2025-08-12 – Integration Pass 4: Safe builders in hot screens; async guards; centralized error reporter usage.
- 2025-08-12 – Micro-interactions: animated like/bookmark, reaction tray.
- 2025-08-12 – Stability: safe stream/future builders, async guards, error reporter stub.
- 2025-08-12 – Nav transitions & List UX: refresh, paging, empty/error states. (Committed on fallback branch `work` due to branch creation restrictions.)
- 2025-08-12 – Composer V2: drafts & scheduling (route-only).
- 2025-08-12 – Link Preview module + demo screen (route-only).
- 2025-08-12 – i18n scaffolding (EN/FR) with dev sandbox; no app wiring yet.

- 2025-08-12 – Notifications v2: per-type prefs, in-app inbox, batched push.

- 2025-08-12 – Reposts/Quote posts; Saved Collections; Share to Story.
- 2025-08-12 – Profiles v2: creator analytics, pinned post, richer bios.
- 2025-08-12 – Stories v2 with overlay editor; viewer pause/seek; 24h expiry; safe parsing.
- 2025-08-12 – Marketplace v2 (filters/favorites/seller profile), Monetization stubs (tips/subscriptions/purchase intents), Admin analytics dashboard with daily rollups.
- 2025-08-12 – Groups & Events v1: create, join/leave, RSVP, safe parsing.
- 2025-08-13 – Messaging v2 (typing/read receipts/media hardening); Notifications v1 (opt-in + Function trigger).
- 2025-08-13 – Search, hashtag index, trending chips.
- 2025-08-15 – Added discovery ranking, onboarding, AR camera, shorts module, marketplace, growth, moderation and analytics updates.
- 2025-08-12 – Shorts/Marketplace MVP; safe empty-states; type-safe Firestore parsing.
- 2025-08-12 – Hardened feed parsing with safe numeric/list handling and added empty-state guards for Shorts and Marketplace screens.
- 2025-08-12 – Add GitHub Actions CI: analyze, format check, tests with coverage, and web release build.
- 2025-08-12 – Project policy update: allow branch creation/switching and new dependencies with DEP records. If branch switching was forbidden by runtime, changes were committed directly to `dev` (fallback).

- 2025-08-12 – Safety & Privacy v2: mute words, reply limits, private account, block/mute manager (route-only).
- 2025-08-12 – Fix compile errors: Shorts route const call; trending chips state; stories type; chat upload progress param; message status helper; non-const constructors in events screens.
- 2025-08-12 – Fix: remove invalid `const` usage for EventsListScreen in home_screen.dart; adjust const lists if present.
- 2025-08-12 – UI Kit: tokens, motion, skeletons, progressive images.
- 2025-08-12 – Integration Pass 1: ProgressiveImage + Skeletons + SafeBuilders + AnimatedLike/Bookmark in Feed, Shorts, Marketplace.
- 2025-08-12 – docs(policy): allow nav bar and feed ranking edits with flags + measurement.
- 2025-08-12 America/New_York – docs: add App-Origin Trigger Catalog, JSON rules, and UC flow rewrites.

- 2025-08-12 – feat(triggers,ranking): add Trigger Orchestrator (v1) + UI widgets + Discovery Ranking V2 skeleton; no integration yet.
