# Firebase Backend — Source of Truth & Automation

This repo owns the Firebase backend. **Do not make console-only changes.**  
All future changes must update these files and let CI deploy:

- `firestore.rules` — Firestore access control
- `storage.rules` — Storage access control
- `firestore.indexes.json` — composite indexes
- `firebase.json`, `.firebaserc` — project wiring
- `functions/**` — Cloud Functions

### Based on current console (screenshots)
- **Storage folders**: `chat_media/`, `event_headers/`, `images/`, `profile_images/`, `stories/`, `stories_media/`, `videos/`.
- **Firestore**: visible paths under `artifacts/<app>/public/data` and collections `posts`, `stories`, `chats`, `users`.
- **Indexes**: composite indexes for `chats` (participants + lastMessage*) and `posts` (authorId/mediaType/timestamp).
- **Functions**: `syncUnreadMessageCountOnRead`, `incrementUnreadMessageCount` are present.

### How to deploy
- **CI:** push to `dev` with changes to rules/indexes/functions → GitHub Actions runs **Firebase Deploy** automatically.
- **Local:** authenticate with `firebase login`, then:
  ```bash
  ./scripts/firebase_deploy.sh fouta-app
  ```

GitHub Secret required
FIREBASE_SERVICE_ACCOUNT: JSON of a service account with Firebase Admin + Cloud Functions Admin.
Save it in repo secrets → Actions will use it for deploys.

Policy for future AIs
Edit only the files above. Never rely on manual console steps.

If adding a new feature that needs a collection or bucket path, update rules & indexes in this repo and include a one-line note in your PR.

Keep rule diffs minimal and add comments referencing the feature & PR.
