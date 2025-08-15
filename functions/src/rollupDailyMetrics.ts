import {onSchedule} from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

const APP_ID = 'fouta-app';
const db = admin.firestore();

export async function countPaged(
  q: FirebaseFirestore.Query,
  page = 500,
): Promise<number> {
  let total = 0;
  let cursor: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  while (true) {
    let query = q;
    if (cursor) {
      query = query.startAfter(cursor);
    }
    const snap = await query.limit(page).get();
    total += snap.size;
    if (snap.size < page) break;
    cursor = snap.docs[snap.docs.length - 1];
  }
  return total;
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
    return countPaged(base.orderBy('createdAt'));
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
      {merge: true},
    );
});
