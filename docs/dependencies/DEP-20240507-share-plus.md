# DEP: share_plus
Date: 2024-05-07
Author: AI Agent
Status: Proposed

## Purpose
Enable native platform sharing to invite friends with referral codes.

## Package
- Name: share_plus
- Link: https://pub.dev/packages/share_plus
- License: BSD-3-Clause

## Alternatives considered
- Manual platform channels — more code and maintenance.
- url_launcher — cannot open native share sheet.

## Platform impact
- Android: no changes.
- iOS: no changes.
- Web: no changes.

## Data, privacy & security
Shares user-provided referral code via OS share sheet; no data retained.

## Test & rollout plan
Verify sharing locally and in CI with widget tests.
Roll out fully after CI passes.

## Removal plan
Revert this commit and remove dependency from `pubspec.yaml`.

