import {onSchedule} from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

const APP_ID = 'fouta-app';
const db = admin.firestore();

// Aggregates daily metrics for the previous UTC day.
// TODO: paginate queries for large datasets to avoid exceeding quotas.
export const rollupDailyMetrics = onSchedule('0 0 * * *', async () => {
  const now = new Date();
  const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - 1));
  const end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const key = start.toISOString().slice(0, 10);

  async function count(path: string) {
    const snap = await db
        .collection(path)
        .where('createdAt', '>=', start)
        .where('createdAt', '<', end)
        .get();
    return snap.size;
  }

  const dau = await count(`artifacts/${APP_ID}/public/data/users`);
  const posts = await count(`artifacts/${APP_ID}/public/data/posts`);
  const shortViews = await count(`artifacts/${APP_ID}/public/data/shorts`);
  const purchaseIntents = await count(`artifacts/${APP_ID}/public/data/monetization/intents`);

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
