import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const queueNotification = functions.firestore
  .document('artifacts/{appId}/public/data/{collection}/{docId}/interactions/{interactionId}')
  .onCreate(async (snap) => {
    const data = snap.data();
    const uid = data?.targetUid;
    if (!uid) return;
    await db
        .collection('notifQueue')
        .doc(uid)
        .collection('items')
        .doc(Date.now().toString())
        .set({
          type: data.type,
          actorId: data.actorId,
          postId: data.postId,
          commentId: data.commentId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
  });

export const dispatchQueuedNotifications = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    const queueSnap = await db.collection('notifQueue').get();
    for (const userDoc of queueSnap.docs) {
      const uid = userDoc.id;
      const itemsSnap = await userDoc.ref.collection('items').get();
      if (itemsSnap.empty) continue;
      const prefsDoc = await db
          .collection('artifacts')
          .doc(process.env.APP_ID || 'fouta-app')
          .collection('public')
          .doc('data')
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('notifications')
          .get();
      const prefs = prefsDoc.data() || {};
      const allowed = itemsSnap.docs.filter((d) => prefs[d.get('type')] !== false);
      const inboxRef = db
          .collection(`artifacts/${process.env.APP_ID || 'fouta-app'}/public/data/notifications/${uid}/items`);
      const batch = db.batch();
      let count = 0;
      for (const doc of allowed) {
        batch.set(inboxRef.doc(), { ...doc.data(), read: false });
        batch.delete(doc.ref);
        count++;
      }
      await batch.commit();
      if (count > 0) {
        console.log(`Sending ${count} notifications to ${uid}`);
      }
    }
  });
