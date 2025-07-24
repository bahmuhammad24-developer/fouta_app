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

        return batch.commit();
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