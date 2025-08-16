# Firebase CI/CD Deploy Journey (fouta-app)

Canonical record of how we got GitHub Actions + Firebase deploys working for **fouta-app**. This prevents re-diagnosing known issues.

**Project ID:** `fouta-app`  
**Deployer SA:** `ci-firebase-deploy@fouta-app.iam.gserviceaccount.com`  
**Runtime SAs:**  
- App Engine default — `fouta-app@appspot.gserviceaccount.com`  
- Compute Engine default — `<PROJECT_NUMBER>-compute@developer.gserviceaccount.com`

---

## Issues & Fixes

### 1) Storage rules error
**Error:** `Could not find rules for the following storage targets: rules`  
**Fix:** Removed `:rules` target; `firebase.json` uses:
```json
"storage": { "rules": "storage.rules" }
```

### 2) Firestore index 409 (“already exists”)

**Fix:** Split deploy:

```
firebase deploy --only firestore:rules,storage
```

Guarded step for firestore:indexes that ignores 409 only.

### 3) Token auth deprecation

**Fix:** Use ADC via google-github-actions/auth@v2 with create_credentials_file: true.
Removed all --token / FIREBASE_TOKEN.

### 4) IAM for Functions (Gen-2)

Granted the deployer SA and service agents the required roles:

ActAs on runtime SAs:

roles/iam.serviceAccountUser on fouta-app@appspot.gserviceaccount.com

roles/iam.serviceAccountUser on <PROJECT_NUMBER>-compute@developer.gserviceaccount.com

Agents:

Pub/Sub service agent — roles/pubsub.publisher

Eventarc service agent — roles/eventarc.eventReceiver

Cloud Build SA — roles/run.admin, roles/artifactregistry.writer, and ActAs on runtime SA

Cloud Run service agent — ActAs on runtime SA

Legacy gs agent — roles/pubsub.publisher

### 5) Storage trigger region mismatch

Error: function in us-central1 cannot listen to bucket in us-east1
Fix: Set { region: 'us-east1' } on storage triggers (v2 options or functions.region('us-east1') in v1). Other triggers unchanged.

### 6) Artifact Registry cleanup warning

Fix: Add cleanup policies on gcf-artifacts in us-east1 and us-central1 (delete images older than 30 days).
Repo script: tools/set_cleanup_policies.sh.

## Final State

CI uses ADC (no tokens).

Functions deploy succeeds in us-central1 and us-east1.

All required IAM bindings are in place.

Artifact cleanup policies set; deploys no longer warn.

## Also see

docs/ci-auth.md — CI auth & IAM policy (ADC only)

docs/ai-collaboration.md — AI rules (always read full repo)

tools/set_cleanup_policies.sh — reapply Artifact Registry cleanup

Last updated: 2025-08-16
