Fixed Firestore index deploy error: "Must contain exactly one of order, arrayConfig, vectorConfig" for `visibility` field.

Added `"order": "ASCENDING"` to `visibility` field entries in `firestore.indexes.json`.
