# CI Authentication & IAM Policy for Firebase Deploys

This document describes how GitHub Actions authenticate and what IAM bindings are required for deploying Firebase (Firestore, Storage, Functions, Hosting) in the **fouta-app** project.

---

## Project Information
- **Project ID:** `fouta-app`
- **Deployer Service Account (used by GitHub Actions):**  
  `ci-firebase-deploy@fouta-app.iam.gserviceaccount.com`
- **Runtime Service Account (used by Cloud Functions at runtime):**  
  `fouta-app@appspot.gserviceaccount.com`

---

## CI Authentication Policy
- GitHub Actions must authenticate using **Google ADC** via `google-github-actions/auth@v2`.
- Always set `create_credentials_file: true` in the auth step.
- **Do not** use Firebase CLI tokens (`FIREBASE_TOKEN`) or `--token` flags.
- Firebase CLI should be pinned to a stable version (e.g., `14.10.1`) to avoid index deploy regressions.

---

## IAM Role Requirements

### Required APIs
The following APIs must be enabled in the project (safe to re-run):
- Cloud Functions
- Cloud Run
- Artifact Registry
- Cloud Build
- IAM Credentials
- Firestore
- Cloud Storage
- Firebase

### Role Bindings
The deployer service account (`ci-firebase-deploy@fouta-app.iam.gserviceaccount.com`) needs the following:

1. **ActAs permission** on the runtime service account:  
   ```bash
   gcloud iam service-accounts add-iam-policy-binding fouta-app@appspot.gserviceaccount.com \
     --member="serviceAccount:ci-firebase-deploy@fouta-app.iam.gserviceaccount.com" \
     --role="roles/iam.serviceAccountUser" \
     --project "fouta-app"
   ```

Project-level roles:

```bash
gcloud projects add-iam-policy-binding fouta-app \
  --member="serviceAccount:ci-firebase-deploy@fouta-app.iam.gserviceaccount.com" \
  --role="roles/cloudfunctions.developer"

gcloud projects add-iam-policy-binding fouta-app \
  --member="serviceAccount:ci-firebase-deploy@fouta-app.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding fouta-app \
  --member="serviceAccount:ci-firebase-deploy@fouta-app.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"
```

Verification

To check if the deployer can “act as” the runtime service account:

```bash
gcloud iam service-accounts get-iam-policy fouta-app@appspot.gserviceaccount.com \
  --project "fouta-app" \
  --format="table(bindings.role, bindings.members)"
```

CI Workflow Notes

The deploy workflow is located at .github/workflows/firebase-deploy.yml.

A policy banner has been added at the top of the YAML file documenting that ADC is the only approved method.

Firestore index deploy is split out with a guard for 409 “already exists” errors.

Last updated: 2025-08-16

