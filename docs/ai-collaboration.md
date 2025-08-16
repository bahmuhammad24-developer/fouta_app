# AI Collaboration Rules for the Fouta App Repository

This file defines mandatory rules for any AI assistant working on this repo.  

---

## Rule 1 — Always Read the Full Repo
- Before giving any response, the AI must **always read the complete GitHub project** (code, workflows, and docs).
- Do not skip this step. Do not rely only on partial memory or assumptions.
- Every answer must be grounded in the actual project files.

---

## Rule 2 — Do Not Ask for Already Documented Data
- The following data is fixed and **must never be asked for again**:
  - **Project ID:** `fouta-app`
  - **Deployer Service Account:** `ci-firebase-deploy@fouta-app.iam.gserviceaccount.com`
  - **Runtime Service Account:** `fouta-app@appspot.gserviceaccount.com`
- IAM bindings and Firebase deploy instructions are permanently documented in:
  - [`docs/ci-auth.md`](./ci-auth.md)

---

## Rule 3 — Authentication Policy
- Always authenticate Firebase deploys using **Google ADC** via `google-github-actions/auth@v2`.
- Always set `create_credentials_file: true`.
- **Never** use Firebase CLI tokens (`FIREBASE_TOKEN`) or `--token`.

---

## Rule 4 — Workflow Guidance
- Firestore index deploys must be handled in a **separate guarded step** to gracefully ignore 409 "already exists" errors.
- Cloud Functions deploys require `iam.serviceAccountUser` on the runtime SA.
- Reference the [CI Auth Policy](./ci-auth.md) for the exact IAM roles and commands.

---

## Rule 5 — Documentation First
- If clarification is needed, always **check repo docs first**.
- If something is missing, update documentation rather than repeatedly asking the same questions.

---

**Last updated:** 2025-08-16

