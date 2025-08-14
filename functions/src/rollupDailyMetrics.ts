import {onSchedule} from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

const APP_ID = 'fouta-app';
const db = admin.firestore();
export const PAGE_SIZE = 1000;

export async function paginatedCount(q: FirebaseFirestore.Query, pageSize = PAGE_SIZE): Promise<number> {
  let total = 0;
  let query: FirebaseFirestore.Query = q.limit(pageSize);
  while (true) {
    const snap = await query.get();
    total += snap.size;
    if (snap.size < pageSize) break;
    const last = snap.docs[snap.docs.length - 1];
    query = q.startAfter(last).limit(pageSize);
  }
  return total;
}

export async function paginatedCount(
  query: FirebaseFirestore.Query,
  limit = 500,
): Promise<number> {
  let total = 0;
  let q: FirebaseFirestore.Query = query.orderBy('createdAt').limit(limit);
  while (true) {
    const snap = await q.get();
    total += snap.size;
    if (snap.size < limit) break;
    const last = snap.docs[snap.docs.length - 1];
    q = q.startAfter(last).limit(limit);
  }
  return total;
}

export async function countPaged(
  query: FirebaseFirestore.Query,
  pageSize = 500,
): Promise<number> {
  let count = 0;
  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  while (true) {
    let q = query;
    if (lastDoc) {
      q = q.startAfter(lastDoc);
    }
    q = q.limit(pageSize);
    const snap = await q.get();
    count += snap.size;
    if (snap.size < pageSize) {
      break;
    }
    lastDoc = snap.docs[snap.docs.length - 1];
  }
  return count;
}

// Aggregates daily metrics for the previous UTC day.
export const rollupDailyMetrics = onSchedule('0 0 * * *', async () => {
  const now = new Date();
  const start = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - 1),
  );
  const end = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  );
  const key = start.toISOString().slice(0, 10);


  async function count(path: string) {

    const base = db
      .collection(path)
      .where('createdAt', '>=', start)
      .where('createdAt', '<', end);
    return paginatedCount(base);

  }

  const dau = await count(`artifacts/${APP_ID}/public/data/users`);
  const posts = await count(`artifacts/${APP_ID}/public/data/posts`);
  const shortViews = await count(`artifacts/${APP_ID}/public/data/shorts`);
  const purchaseIntents = await count(
    `artifacts/${APP_ID}/public/data/monetization/intents`,
  );


  await db
    .collection(`artifacts/${APP_ID}/public/data/metrics/daily`)
    .doc(key)
    .set(
      {
        dau,
        posts,
        shortViews,
        purchaseIntents,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },

      { merge: true },

    );
});
