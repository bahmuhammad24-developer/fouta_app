# Challenges Backend Setup

## Firestore Collections
- `challenges/{id}` – challenge documents authored by users.  
  - Auth required for create; `authorId` must equal the requesting `uid`.  
  - Subcollections:
    - `comments/{cid}` – authenticated create with matching `authorId`; **TODO:** enforce length limits.
    - `votes/{uid}` – one document per user; writes use server timestamp.

## Rules
Stubbed security rules live in [`/firestore.rules`](../../../firestore.rules).  
They gate writes to the collections above and include **TODOs** for safe field validation.

## Index Queries
- `challenges`: `where(createdAtDay == X)` + `orderBy(score desc)`
- `challenges`: `where(tagKeys array-contains Y)` + `orderBy(createdAt desc)`

Definitions reside in [`/firestore.indexes.json`](../../../firestore.indexes.json).

## Deployment
Use Firebase automation CI to deploy rules and indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

