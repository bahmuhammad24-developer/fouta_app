# Contributor Guide

## Project
- Default base branch: `dev`. Never push directly to `main`.
- Languages: Flutter (web-first) + Firebase Functions (Node 20).

## Local checks to run before any PR
- `flutter pub get`
- `flutter analyze`
- `dart format --output=none --set-exit-if-changed .`
- `flutter test --no-pub --coverage`
- if `/functions` exists: `npm ci` && `npm test --if-present`
- `flutter build web --release`  # smoke-test

## PR requirements
- Title uses Conventional Commits.
- Summary: what/why/how.
- Risks: top 5 with mitigations.
- Tests: list added/updated tests and show the relevant passing output.
- Migration notes (if any).
- Citations to changed files and test output using Codex’s file/terminal citation format.

## Repo guardrails
- Return complete file replacements (no ellipses).
- Don’t change the custom feed sorting logic.
- Don’t add new runtime dependencies without noting rationale and security review.
- No bottom nav on Login/Signup screens.
