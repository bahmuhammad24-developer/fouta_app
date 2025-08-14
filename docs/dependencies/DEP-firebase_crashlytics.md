# DEP: firebase_crashlytics
Date: 2024-05-16
Author: AI Assistant
Status: Adopted

## Purpose
Provide production crash reporting and stack trace aggregation.

## Package
- Name: firebase_crashlytics
- Link: https://pub.dev/packages/firebase_crashlytics
- License: BSD-3-Clause

## Alternatives considered
- Sentry — feature-rich but requires separate account and SDK.
- AppCenter — not integrated with Firebase ecosystem.

## Platform impact
- Android: Adds Crashlytics Gradle plugin; follow FlutterFire setup.
- iOS: Adds Crashlytics run script in Xcode build phases.
- Web: Unsupported; flag remains false on web builds.

## Data, privacy & security
Crash reports contain stack traces and non-PII metadata. Ensure no sensitive user data is logged.

## Test & rollout plan
- Unit tests validate forwarding when flag enabled.
- Gradual rollout by enabling define per build flavor.

## Removal plan
- Remove dependency from `pubspec.yaml` and disable flag.
