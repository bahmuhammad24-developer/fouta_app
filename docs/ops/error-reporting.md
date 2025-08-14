# Error Reporting

`CRASHLYTICS_ENABLED` controls forwarding of runtime errors to
`FirebaseCrashlytics`. The flag defaults to `false` to avoid sending reports
from local or test environments.

## Usage
1. Set `AppFlags.crashlyticsEnabled = true` at startup for production builds.
2. Ensure errors are reported through `ErrorReporter.report`.
3. Crashlytics receives only error strings and stack traces; avoid attaching
   sensitive user data.

## Rollback
- Disable by setting `AppFlags.crashlyticsEnabled = false`.
- If issues persist, revert the enabling commit.
