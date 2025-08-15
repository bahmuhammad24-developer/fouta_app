# Contributor Guide

## Project
- Base branch: `dev` (protected `main`).
- Tech: Flutter (web-first) + Firebase Functions (Node 20).

## Local checks (before PR)
- `flutter pub get`
- `flutter analyze`
- `dart format --output=none --set-exit-if-changed .`
- `flutter test --no-pub --coverage`
- If `/functions` exists: `npm ci && npm test --if-present`
- Optional smoke: `flutter build web --release`

## PR requirements
- Conventional Commit title.
- Summary (what/why/how), top 5 risks + mitigations, test output, migration notes.
- Cite changed files and test logs.

## Repo policy
### Change Process (Codex Prompts Only)
All changes to project code or documentation must be initiated and executed via Codex prompts.

Do not push manual edits directly.

- Do not add or commit `pubspec.lock`. Dependency locking is handled at build time by `flutter pub get`.
Each change should come as a clear, reviewable Codex prompt that:

- Names the branch (e.g., feat/... or fix/...)
- Lists precise file paths and line-level changes
- Includes tests and docs updates (if applicable)
- States acceptance criteria and rollback notes

Rationale: This guarantees deterministic, reviewable updates and consistent multi-role consideration (PM/Dev/Tester/Designer/DevOps/Data/Security).

- **Outputs:** The AI must provide detailed prompts for the codex agent specifying exactly which files to edit, what content to add or modify, and why.  Do not produce partial snippets without context.  Each prompt must include the relevant spec ID, file paths, and a rollback plan.
- **Branches:** Agents may create/switch branches. If blocked, commit on `dev` and note fallback.
- **Dependencies:** Allowed when a DEP record is added and CI passes (see DEP policy).
- **Spec-driven:** No changes may be made without an approved one-page feature spec in `/docs/specs/<ticket>_v<version>.md` covering context, requirements, data contracts, acceptance criteria, runtime flags, metrics, risks, test plan, and rollback steps.
- **Budgets:** CI must fail if p95 latency exceeds 800 ms or if storage/egress grows more than 20 % month‑over‑month.
- **Auth screens:** No bottom nav on Login/Signup.

### No-Conflict Codex Prompts
- See [docs/process/no-conflict-codex-prompts.md](docs/process/no-conflict-codex-prompts.md)
- One ticket → one branch → one small PR
- Avoid touching files already edited by open PRs
- Prefer additive edits; do not mass-reformat
- Prefer adding new files and tiny call-site adapters over large refactors.
- When wiring navigation, use a small helper (e.g., create_product_nav.dart) and minimally touch one caller.
- Avoid editing files touched by open PRs; if uncertain, prefer AppBar action additions or separate entry-points.
- When introducing UI changes, prefer aligning with tokens and components defined in docs/design/system. Avoid ad-hoc styles that conflict with tokens.

### Multi‑role awareness
The AI must integrate the perspectives of PM, Developer, Tester, Designer, DevOps, Data, Security, Accessibility, and Product in every response. For each request, it should explicitly address requirements and acceptance criteria (PM), implementation details (Dev), testing needs (Tester), UI/a11y considerations (Designer), deployment and cost impacts (DevOps), data and migrations (Data), security/privacy concerns (Security), and overall policy compliance (Product).

## Navigation & Feed policy (updated)
- **Nav bar changes are allowed** when:
  1) Changes are behind a **feature flag** (e.g., `remoteConfig.nav_variant = 'A'|'B'` or Firestore config).
  2) A short measurement plan is included (click‑through, dwell time, nav errors).
  3) A rollback note is included in the PR.

- **Feed ranking changes are allowed** when:
  1) Implemented as a **new strategy class** (e.g., `DiscoveryRankingV2`) without deleting the previous one.
  2) Gated by a **feature flag** (e.g., `feed_ranking='v2'`).
  3) Instrumented for **watch time, completes, shares/DMs, follows-after-view**, with a 7‑day decay.
  4) PR includes a **rollback plan** and index notes (Firestore queries must be indexable).

When generating prompts for codex, document the flag names, the metrics to track, and the rollback plan.
