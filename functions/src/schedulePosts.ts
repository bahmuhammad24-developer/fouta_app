import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const APP_ID = process.env.APP_ID || 'fouta-app';

/**
 * Placeholder scheduler that publishes due posts and removes them.
 * In production this would move `payload` into the main posts collection.
 */
export const schedulePosts = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const usersCol = admin
      .firestore()
      .collection(`artifacts/${APP_ID}/public/data/users`);
    const users = await usersCol.listDocuments();
    for (const user of users) {
      const schedCol = user.collection('scheduled');
      const snap = await schedCol.where('publishAt', '<=', now).get();
      for (const doc of snap.docs) {
        const payload = doc.data().payload;
        // TODO: publish payload to posts collection
        await doc.ref.delete();
      }
    }
    return null;
  });
