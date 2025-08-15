# Firebase deploy workflow
- Requires GitHub **Repository Secrets**:
  - `FIREBASE_SERVICE_ACCOUNT` — the JSON of a service account with permissions to deploy to your Firebase project (Firebase Admin + Cloud Functions Admin).
  - `FIREBASE_PROJECT_ID` — your project id (e.g., `fouta-app`).
- On push to `dev` touching rules/indexes/functions, CI will authenticate via `google-github-actions/auth` and run `firebase deploy` non-interactively.

# iOS CI
- We ship a standard **Podfile** (no absolute paths). The iOS workflow installs Flutter (stable), runs `pod install`, and builds with `--no-codesign`.

# Local commands
- Deploy backend locally (after `firebase login`):
firebase deploy --only firestore:rules,firestore:indexes,storage:rules,functions --project <PROJECT_ID> --non-interactive

- Rebuild iOS locally:
flutter clean && flutter pub get
cd ios && pod repo update && pod install && cd ..
flutter build ios --no-codesign --debug

