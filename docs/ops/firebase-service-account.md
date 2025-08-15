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

As of 2025-08-15, the Firebase CI deploy step now includes **Cloud Storage rules** in addition to Firestore rules and indexes.

**Key points:**
- `storage.rules` exists in the repo root and defines default access for Firebase Cloud Storage.
- Current default: only authenticated users can read/write.
  ```
  rules_version = '2';
  service firebase.storage {
    match /b/{bucket}/o {
      match /{allPaths=**} {
        allow read, write: if request.auth != null;
      }
    }
  }
  ```
- `firebase.json` contains a `"storage"` section:
```json
"storage": {
  "rules": "storage.rules"
}
```

CI deploy step calls:
```bash
firebase deploy --only firestore:rules,firestore:indexes,storage:rules
```
which now successfully deploys storage rules without missing file errors.

**Maintenance:**
- Update `storage.rules` as needed for tighter or looser permissions.
- Any changes to `storage.rules` will automatically be deployed by CI if committed to the tracked branch.
- Ensure the Firebase Storage API remains enabled in GCP for the target project.
