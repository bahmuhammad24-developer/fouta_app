# Firestore Indexes

The project seeds composite indexes via [`firestore.indexes.json`](../../firestore.indexes.json).

## Adding or updating an index

1. Run your query. If Firestore returns `FAILED_PRECONDITION: The query requires an index`,
   open the URL provided in the error message. It leads directly to the Firebase console
   with the fields prefilled.
2. Create the index in the console. Wait for it to build.
3. Back in the repo, export the definitions to `firestore.indexes.json`:
   ```bash
   firebase firestore:indexes
   ```
4. Commit the updated file so all environments provision the same index.

Include the console URL in your PR description for reviewers.
