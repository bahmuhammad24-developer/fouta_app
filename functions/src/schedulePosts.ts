import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {checkSafetyRules} from './safetyRules';

const APP_ID = process.env.APP_ID || 'fouta-app';


export async function publishDueScheduledPosts(
  db: FirebaseFirestore.Firestore,
  now: FirebaseFirestore.Timestamp,
): Promise<void> {

  const usersCol = db.collection(`artifacts/${APP_ID}/public/data/users`);
  const users = await usersCol.listDocuments();
  for (const user of users) {
    const schedCol = user.collection('scheduled');

    const snap = await schedCol.where('publishAt', '<=', now).get();
    for (const doc of snap.docs) {
      const payload = doc.data().payload || {};
      const result = checkSafetyRules(payload);
      if (result.ok) {
        await db.collection(`artifacts/${APP_ID}/public/data/posts`).add({
          content: payload.content,
          media: payload.media,
          createdBy: user.id,
          visibility: payload.visibility,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        await db
          .collection(`artifacts/${APP_ID}/public/data/moderation/scheduled`)
          .doc(doc.id)
          .set({
            reason: result.reason,
            createdBy: user.id,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
      }
      await doc.ref.delete();

    }
  }
}

export const schedulePosts = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    if (process.env.SCHEDULED_POSTS_ENABLED !== 'true') {
      functions.logger.info('scheduled posts disabled');
      return null;
    }
    const now = admin.firestore.Timestamp.now();

    await publishDueScheduledPosts(admin.firestore(), now);

    return null;
  });
