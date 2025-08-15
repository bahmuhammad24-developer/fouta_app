# Firebase CI Setup - 2025-08-15

- Switched from GOOGLE_APPLICATION_CREDENTIALS-only to **gcloud access token** passed to `firebase --token`, which reliably satisfies Firebase CLI auth in CI.
- Emulator validation step also uses `--token` to avoid auth warnings.
