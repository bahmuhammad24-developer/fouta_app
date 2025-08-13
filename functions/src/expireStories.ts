import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const APP_ID = process.env.APP_ID || 'fouta-app';

export const expireStories = functions.pubsub
  .schedule('every 60 minutes')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const col = admin
      .firestore()
      .collection(`artifacts/${APP_ID}/public/data/stories`);
    const snap = await col.where('expiresAt', '<', now).get();
    const batch = admin.firestore().batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    return null;
  });
