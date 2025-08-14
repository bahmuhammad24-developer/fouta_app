# DEP: firebase_crashlytics
Date: 2025-08-14
Author: ChatGPT
Status: Adopted

## Purpose
Provide Crashlytics-based runtime error reporting controlled by a flag.

## Package
- Name: firebase_crashlytics
- Link: https://pub.dev/packages/firebase_crashlytics
- License: BSD-3-Clause

## Alternatives considered
- Sentry — broader features but heavier setup.
- Custom logging — no external visibility or aggregation.

## Platform impact
- Android: No additional manifest changes.
- iOS: No new entitlements; Pod install handled by FlutterFire.
- Web: No web-specific changes.

## Data, privacy & security
Sends error strings and stack traces to Firebase; avoid PII in messages.

## Test & rollout plan
Unit tests verify Crashlytics invocation. Roll out behind
`CRASHLYTICS_ENABLED` flag.

## Removal plan
Remove dependency and flag usage, run `flutter pub get`, and delete this DEP.
