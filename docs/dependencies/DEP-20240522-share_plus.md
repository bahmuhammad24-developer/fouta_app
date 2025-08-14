# DEP: share_plus
Date: 2025-05-22
Author: ChatGPT
Status: Proposed

## Purpose
Enable cross-platform share sheets for referral invitations.

## Package
- Name: share_plus
- Link: https://pub.dev/packages/share_plus
- License: BSD-3-Clause

## Alternatives considered
- Platform channel integration — more maintenance, less reuse.
- In-app copy to clipboard — worse UX.

## Platform impact
- Android: none
- iOS: none
- Web: none

## Data, privacy & security
Shares only a user-provided message; referral codes are random and contain no PII.

## Test & rollout plan
Covered by widget test and manual QA; include in next beta build.

## Removal plan
Remove dependency from `pubspec.yaml` and delete share handler on rollback.
