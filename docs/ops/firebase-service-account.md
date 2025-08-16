# Firebase Service Account

This document explains how to configure a Firebase service account for CI/CD.

### 8) How CI uses it (token approach)
- GitHub Actions authenticates to Google Cloud with the Service Account (via `google-github-actions/auth`).
- The workflow runs:
  ```
  gcloud auth print-access-token
  ```
  and passes that short-lived token to Firebase CLI with:
  ```
  firebase deploy --token "<access token>"
  ```
- This removes the need for interactive `firebase login` and prevents the "have you run firebase login?" error in CI.

### APIs to enable (once per project)
- Cloud Functions API
- Cloud Build API
- Firebase Management API

### 9) Cloud Storage Rules in CI

As of 2025-08-15, CI deploys **Cloud Storage rules** alongside Firestore rules and indexes.

**What’s in repo**
- `storage.rules` at the repo root (default: only authenticated users can read/write).
- `firebase.json` includes:
  ```json
  "storage": {
    "rules": "storage.rules"
  }
  ```

**CI behavior**

  The workflow runs:

  ```bash
  firebase deploy --only firestore:rules,firestore:indexes,storage
  ```
  which deploys Storage rules using the configuration in `firebase.json`.

**Tips**

  - Tighten/relax rules by editing `storage.rules`; CI will deploy on merge.
  - For multi-bucket setups, add Storage targets in `firebase.json` and corresponding rules files; include those targets via `--only storage:<name>`.

### 10) Storage deploy flag (targets vs rules file)

Use:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Do not use a filter like `storage:<name>` for the rules deploy; for example, targeting a bucket named `rules` will fail. In the Firebase CLI, `storage:<name>` refers to a Storage target named `<name>` (created via `firebase target:apply storage <name> <bucket>`).

Our repo uses a rules file wired in `firebase.json`:

```json
"storage": { "rules": "storage.rules" }
```

so the correct filter is simply `--only storage`.
