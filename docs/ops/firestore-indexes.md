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

## Field Rule and Decision Guide

When defining fields inside `firestore.indexes.json` → `indexes[].fields[]`, **each field object must contain exactly one of**:
- `"order"`: `"ASCENDING"` or `"DESCENDING"` — for sorting and equality/range queries.
- `"arrayConfig"`: `"CONTAINS"` — for `array-contains` / `array-contains-any` queries.
- `"vectorConfig"`: `{...}` — for vector search.

Common patterns:
- Equality / range / order-by queries on a scalar field → `order: "ASCENDING"` (or `"DESCENDING"` depending on your query).
- `array-contains` / `array-contains-any` → `arrayConfig: "CONTAINS"`.
- Vector search → `vectorConfig` per Firestore vector schema.

**CI Guardrail**
- We added `scripts/validate-firestore-indexes.mjs` and a CI step `npm run check:indexes` to block deploys if a field is missing the required property.
- If you see an error like:
  > Must contain exactly one of "order,arrayConfig,vectorConfig"
  open `firestore.indexes.json` and fix the problematic field(s).

**Default we apply automatically**
- If a field lacks all three, we normalize it to `order: "ASCENDING"`; this unblocks deploys. Adjust later to `DESCENDING` or `arrayConfig` if your query needs it.
