# Error Reporting Ops Guide

Integrate Firebase Crashlytics to capture uncaught errors.

## Setup
1. Add Crashlytics to your Firebase project and configure platform-specific build steps per [FlutterFire docs](https://firebase.flutter.dev/docs/crashlytics/overview).
2. Provide `--dart-define=CRASHLYTICS_ENABLED=true` when building or testing to enable forwarding.
3. Ensure Firebase initialization runs before any errors are reported.

## Verification
- Trigger a test exception in debug builds and confirm it appears in the Crashlytics dashboard.

## Rollback
- Rebuild without the `CRASHLYTICS_ENABLED` define or set it to `false`.
