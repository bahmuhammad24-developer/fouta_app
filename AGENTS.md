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
- **File output:** Full file replacements (no ellipses).
- **Branches:** Agents may create/switch branches. If blocked, commit on `dev` and note fallback.
- **Dependencies:** Allowed when a DEP record is added and CI passes (see DEP policy).
- **Auth screens:** No bottom nav on Login/Signup.

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
