# Firestore Indexes: Source of Truth = firestore.indexes.json

We treat `firestore.indexes.json` as the single source of truth. CI enforces this by
deploying Firestore indexes with `--force`:

- `--force` tells Firebase to reconcile server state to match the file:
  - Create any indexes in the file that don’t exist remotely.
  - Delete any remote indexes that are not in the file (including those created in the Console in the past).
- This prevents CI failures like:
  `HTTP Error: 409, index already exists`
  which appears when a remote index conflicts with a "new" index in the file.

### When is `--force` safe?
- Safe if the file is accurate and complete for the app’s queries.
- We include all composite indexes we rely on in `firestore.indexes.json` and version them in Git.

### If you need to keep a Console-only index
- Export the remote index to the repo:  
  `firebase firestore:indexes > firestore.indexes.json`
- Review the diff (make sure we aren’t re-introducing duplicate/invalid definitions).
- Commit, then CI will reconcile.

### Validating the file
CI runs schema validation before deploy. If you add or change indexes, ensure:
- Exactly one of `order`, `arrayConfig`, or `vectorConfig` per field.
- No duplicate composite definition for a given `collectionGroup` + ordered field list.

### Why a browser GET to the Admin API shows 401
Admin endpoints require OAuth. Opening the raw REST URL in a browser is unauthenticated and will return 401.
CI uses the service account to authenticate; no action is required.
