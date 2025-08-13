# Dependency Policy

We allow adding new runtime and dev dependencies if they are justified and tested.

## Checklist for each new dependency
1. Create a DEP record: copy `docs/dependencies/DEP-TEMPLATE.md` to `docs/dependencies/DEP-YYYYMMDD-<name>.md` and fill it.
2. Update manifests:
   - Flutter: `pubspec.yaml` then `flutter pub get`
   - Functions (if used): `functions/package.json` then `npm ci`
3. Platform notes (if needed):
   - Android: Gradle/`minSdkVersion`, permissions, ProGuard/r8 rules
   - iOS: Pod install, entitlements, Info.plist keys
   - Web: `index.html` tags, service worker updates
4. Docs: Add any setup notes to `README.md`.
5. CI: Confirm `flutter analyze`, `dart format --set-exit-if-changed`, and tests pass.
6. Security: Prefer well‑maintained packages with permissive licenses. Avoid binary blobs.
