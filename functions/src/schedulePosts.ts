import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {checkSafetyRules} from './safetyRules';

const APP_ID = process.env.APP_ID || 'fouta-app';

export async function publishDuePosts(db: FirebaseFirestore.Firestore, now: FirebaseFirestore.Timestamp) {
  const usersCol = db.collection(`artifacts/${APP_ID}/public/data/users`);
  const users = await usersCol.listDocuments();
  for (const user of users) {
    const schedCol = user.collection('scheduled');
    const snap = await schedCol
      .where('publishAt', '<=', now)
      .where('processedAt', '==', null)
      .get();
    for (const doc of snap.docs) {
      const data = doc.data();
      const payload = data.payload || {};
      const violations = checkSafetyRules(payload);
      if (violations.length === 0) {
        await db.collection(`artifacts/${APP_ID}/public/data/posts`).add({
          ...payload,
          userId: user.id,
          createdAt: now,
        });
      } else {
        await user.collection('moderation').add({
          payload,
          reasons: violations,
          createdAt: now,
        });
      }
      await doc.ref.update({processedAt: now});
    }
  }
}

export const schedulePosts = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    if (process.env.SCHEDULED_POSTS_ENABLED !== 'true') {
      return null;
    }
    const now = admin.firestore.Timestamp.now();
    await publishDuePosts(admin.firestore(), now);
    return null;
  });
