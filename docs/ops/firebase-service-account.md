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
