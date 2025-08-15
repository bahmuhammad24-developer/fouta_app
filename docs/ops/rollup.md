# Daily Metrics Rollup

The `rollupDailyMetrics` function aggregates previous-day counts for several collections.
To avoid Firestore timeouts and quotas, counts are paginated using `startAfter` and a
page size of 500 documents.

## Runtime
The job is expected to complete within Firebase's default 540 second limit. In local
emulators with >1000 documents per collection it finishes in under a minute.
