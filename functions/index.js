const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// This function correctly increments both the global and per-chat counters.
exports.incrementUnreadMessageCount = onDocumentCreated(
    "artifacts/fouta-app/public/data/chats/{chatId}/messages/{messageId}",
    async (event) => {
        const snap = event.data;
        if (!snap) {
            console.log("No data associated with the event");
            return;
        }
        const messageData = snap.data();
        const chatId = event.params.chatId;

        const chatRef = db.collection("artifacts/fouta-app/public/data/chats").doc(chatId);
        const chatDoc = await chatRef.get();
        if (!chatDoc.exists) {
            console.log(`Chat document ${chatId} not found.`);
            return;
        }

        const participants = chatDoc.data().participants || [];
        const senderId = messageData.senderId;
        const recipientId = participants.find((id) => id !== senderId);

        if (!recipientId) {
            console.log("Recipient not found in chat.");
            return;
        }

        const recipientRef = db.collection("artifacts/fouta-app/public/data/users").doc(recipientId);
        
        const batch = db.batch();

        batch.update(recipientRef, {
            unreadMessageCount: admin.firestore.FieldValue.increment(1),
        });

        batch.update(chatRef, {
            [`unreadCounts.${recipientId}`]: admin.firestore.FieldValue.increment(1),
        });

        await batch.commit();

        const recipientDoc = await recipientRef.get();
        const tokens = recipientDoc.data().fcmTokens || [];
        if (tokens.length > 0) {
            const payload = {
                tokens: tokens,
                notification: {
                    title: `${messageData.senderName || 'New message'}`,
                    body: messageData.content || 'You have a new message.',
                },
                data: {
                    chatId: chatId,
                    senderId: senderId,
                },
            };
            try {
                await admin.messaging().sendEachForMulticast(payload);
            } catch (error) {
                console.error('Error sending FCM message', error);
            }
        }

        return null;
    });

// **FIXED FUNCTION:** This now correctly listens for updates on the CHAT document.
exports.syncUnreadMessageCountOnRead = onDocumentUpdated(
    "artifacts/fouta-app/public/data/chats/{chatId}",
    async (event) => {
        const beforeSnap = event.data.before;
        const afterSnap = event.data.after;
        if (!beforeSnap || !afterSnap) {
            console.log("Missing before or after data snapshot on chat update.");
            return;
        }
        
        const beforeData = beforeSnap.data();
        const afterData = afterSnap.data();
        const participants = afterData.participants || [];

        // Check each participant to see if their unread count was reset to 0
        for (const userId of participants) {
            const beforeCount = beforeData.unreadCounts?.[userId] || 0;
            const afterCount = afterData.unreadCounts?.[userId] || 0;

            // This condition is met when the client opens a chat and marks it as read.
            if (beforeCount > 0 && afterCount === 0) {
                const countDifference = beforeCount;
                
                const userRef = db.collection("artifacts/fouta-app/public/data/users").doc(userId);
                const userDoc = await userRef.get();

                if (userDoc.exists && (userDoc.data().unreadMessageCount || 0) >= countDifference) {
                     return userRef.update({
                        unreadMessageCount: admin.firestore.FieldValue.increment(-countDifference),
                    });
                }
            }
        }
        return null;
    });

exports.onNewInteraction = onDocumentCreated(
    "artifacts/fouta-app/public/data/{document=**}",
    async (event) => {
        if (!process.env.FCM_SERVER_KEY) {
            console.log("TODO: provide FCM_SERVER_KEY");
            return;
        }
        const path = event.params.document.split("/");
        const data = event.data && event.data.data();
        if (!data) return;

        if (path[0] === "posts" && path.length === 2) {
            const authorId = data.authorId;
            const authorDoc = await db.collection("artifacts/fouta-app/public/data/users").doc(authorId).get();
            const followers = authorDoc.data().followers || [];
            for (const uid of followers) {
                const tokenDoc = await db.collection(`artifacts/fouta-app/public/data/users/${uid}/meta`).doc("token").get();
                if (tokenDoc.exists) {
                    await admin.messaging().send({
                        token: tokenDoc.data().value,
                        notification: {title: "New post", body: data.content || ""},
                    });
                }
            }
        } else if (path[0] === "posts" && path[2] === "comments") {
            const postId = path[1];
            const postDoc = await db.collection("artifacts/fouta-app/public/data/posts").doc(postId).get();
            const recipient = postDoc.data().authorId;
            if (recipient && recipient !== data.authorId) {
                const tokenDoc = await db.collection(`artifacts/fouta-app/public/data/users/${recipient}/meta`).doc("token").get();
                if (tokenDoc.exists) {
                    await admin.messaging().send({
                        token: tokenDoc.data().value,
                        notification: {title: "New comment", body: data.content || ""},
                    });
                }
            }
        } else if (path[0] === "chats" && path[2] === "messages") {
            const chatId = path[1];
            const chatDoc = await db.collection("artifacts/fouta-app/public/data/chats").doc(chatId).get();
            const participants = chatDoc.data().participants || [];
            for (const uid of participants) {
                if (uid === data.senderId) continue;
                const tokenDoc = await db.collection(`artifacts/fouta-app/public/data/users/${uid}/meta`).doc("token").get();
                if (tokenDoc.exists) {
                    await admin.messaging().send({
                        token: tokenDoc.data().value,
                        notification: {title: "New message", body: data.content || "You have a new message."},
                    });
                }
            }
        }
    });
const {onObjectFinalized} = require("firebase-functions/v2/storage");
const sharp = require("sharp");
const {encode} = require("blurhash");
const path = require("path");
const os = require("os");
const fs = require("fs");
const ffmpeg = require("@ffmpeg-installer/ffmpeg");
const ffmpegLib = require("fluent-ffmpeg");
ffmpegLib.setFfmpegPath(ffmpeg.path);

exports.processMedia = onObjectFinalized({ region: "us-east1" }, async (event) => {
  const object = event.data;
  const contentType = object.contentType || "";
  const filePath = object.name;
  const metadata = object.metadata || {};
  const docId = metadata.docId;
  if (!docId) {
    console.log("No docId metadata on uploaded file.");
    return;
  }
  const bucket = admin.storage().bucket(object.bucket);
  const tempLocalFile = path.join(os.tmpdir(), path.basename(filePath));
  await bucket.file(filePath).download({destination: tempLocalFile});
  const mediaRef = db.collection("artifacts/fouta-app/public/data/media").doc(docId);

  try {
    if (contentType.startsWith("image/")) {
      const image = sharp(tempLocalFile);
      const meta = await image.metadata();
      const {width, height} = meta;
      const sizes = [
        {name: "thumb", width: 128},
        {name: "preview", width: 480},
        {name: "full", width: 1080},
      ];
      const urls = {};
      for (const s of sizes) {
        const tempPath = path.join(os.tmpdir(), `${s.name}_${path.basename(filePath)}`);
        await image.clone().resize({width: s.width, withoutEnlargement: true}).jpeg({quality: 80}).toFile(tempPath);
        const destPath = `${path.dirname(filePath)}/${path.parse(filePath).name}_${s.name}.jpg`;
        await bucket.upload(tempPath, {destination: destPath, metadata: {contentType: "image/jpeg"}});
        fs.unlinkSync(tempPath);
        const [signedUrl] = await bucket.file(destPath).getSignedUrl({action: "read", expires: "03-09-2491"});
        urls[`${s.name}Url`] = signedUrl;
      }
      const {data, info} = await image.clone().raw().ensureAlpha().resize(32, 32, {fit: "inside"}).toBuffer({resolveWithObject: true});
      const blurhash = encode(new Uint8ClampedArray(data), info.width, info.height, 4, 4);
      await mediaRef.set({
        ...urls,
        blurhash,
        width,
        height,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
    } else if (contentType.startsWith("video/")) {
      const posterTemp = path.join(os.tmpdir(), `poster_${path.basename(filePath)}.jpg`);
      await new Promise((resolve, reject) => {
        ffmpegLib(tempLocalFile)
          .on("end", resolve)
          .on("error", reject)
          .screenshots({
            count: 1,
            folder: path.dirname(posterTemp),
            filename: path.basename(posterTemp),
            size: "1280x?",
          });
      });
      const posterImage = sharp(posterTemp);
      const meta = await posterImage.metadata();
      const {width, height} = meta;
      const sizes = [
        {name: "thumb", width: 128},
        {name: "preview", width: 480},
        {name: "full", width: 1080},
      ];
      const urls = {};
      for (const s of sizes) {
        const tempPath = path.join(os.tmpdir(), `${s.name}_poster_${path.basename(filePath)}`);
        await posterImage.clone().resize({width: s.width, withoutEnlargement: true}).jpeg({quality: 80}).toFile(tempPath);
        const destPath = `${path.dirname(filePath)}/${path.parse(filePath).name}_${s.name}.jpg`;
        await bucket.upload(tempPath, {destination: destPath, metadata: {contentType: "image/jpeg"}});
        fs.unlinkSync(tempPath);
        const [signedUrl] = await bucket.file(destPath).getSignedUrl({action: "read", expires: "03-09-2491"});
        urls[`${s.name}Url`] = signedUrl;
      }
      const {data, info} = await posterImage.clone().raw().ensureAlpha().resize(32, 32, {fit: "inside"}).toBuffer({resolveWithObject: true});
      const blurhash = encode(new Uint8ClampedArray(data), info.width, info.height, 4, 4);
      await mediaRef.set({
        ...urls,
        blurhash,
        width,
        height,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      fs.unlinkSync(posterTemp);
    }
  } catch (err) {
    console.error("Error processing media", err);
  }
  fs.unlinkSync(tempLocalFile);
});

