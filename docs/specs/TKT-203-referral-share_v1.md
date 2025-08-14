# TKT-203 Referral Share v1

## Context
Users want to invite friends using referral codes. The app currently lacks a native share sheet, limiting growth.

## Requirements
- Add `share_plus` dependency.
- Share referral code via native share sheet.
- Button labeled for accessibility.
- Widget test mocking share call.

## Data Contracts
No new data models.

## Acceptance Criteria
- Share sheet opens with message `Join me on Fouta. Code: <code>`.
- Button exposes a11y label "Share referral code".
- Widget test passes.

## Runtime Flags
None.

## Metrics
- Track referral shares via existing analytics events.

## Risks
- Platform share failures — mitigated with existing error logs.
- Dependency bloat — reviewed via DEP.

## Test Plan
- `flutter test --no-pub --coverage` including new widget test.
- Manual smoke test on device.

## Rollback
- Remove share button and dependency; revert to prior commit.

