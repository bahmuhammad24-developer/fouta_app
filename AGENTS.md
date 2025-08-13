# Contributor Guide

## Project
- Default base branch: `dev`. Do not push directly to `main` (protected).
- Languages: Flutter (web-first) + Firebase Functions (Node 20).

## Local checks to run before any PR
- `flutter pub get`
- `flutter analyze`
- `dart format --output=none --set-exit-if-changed .`
- `flutter test --no-pub --coverage`
- If `/functions` exists: `npm ci && npm test --if-present`
- Optional smoke tests (if environment allows):
  - `flutter build web --release`
  - `flutter build apk --debug` (Android)
  - `flutter build ios --no-codesign` (macOS runner)

## PR requirements
- Title uses Conventional Commits.
- Summary: what / why / how.
- Risks: top 5 with mitigations.
- Tests: list added/updated tests and show relevant passing output.
- Migration notes (if any).
- Citations to changed files and test output (reference paths and commands).

## Repo policy (updated)
- **File output**: Return complete file replacements (no ellipses).
- **Branches**: Agents **may create/switch** branches (feature/*, fix/*, meta/*). If your system forbids it, work on `dev` and note the fallback in the changelog.
- **Dependencies**: Agents **may add runtime or dev dependencies** when all of the following are done:
  1) Create a short DEP record under `docs/dependencies/` using the template (see `DEP-TEMPLATE.md`).
  2) Update `pubspec.yaml` (and `functions/package.json` if applicable), then run `flutter pub get` (or `npm ci`).
  3) Update platform settings if required (Android minSdk/Gradle, iOS Pod settings, Web `index.html`).
  4) Update `README.md` with setup notes if manual steps are needed.
  5) Ensure tests and CI pass.
- **Feed sorting**: Do not modify the custom feed sorting unless a task explicitly authorizes it.
- **Auth screens**: No bottom navigation on Login/Signup.
