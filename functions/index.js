const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * PEMBANTU: Logik Penapisan Bertingkat dengan Kategori
 * Kategori: 'appointments', 'chat', 'emergency', 'dailyCare'
 */
async function sendTargetedNotification(userId, title, body, category = 'general') {
    try {
        // 1. Check Global HQ Switch
        const hqDoc = await admin.firestore().doc('app_settings/notifications').get();
        const isGlobalEnabled = hqDoc.exists ? hqDoc.data().isNotificationEnabled : true;
        if (!isGlobalEnabled) return;

        // 2. Check User Preferences
        const prefDoc = await admin.firestore().doc(`users/${userId}/settings/preferences`).get();
        const userDoc = await admin.firestore().doc(`users/${userId}`).get();

        if (!userDoc.exists) return;
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        if (!fcmToken) return;

        // Default to true if preferences doc doesn't exist yet
        let isCategoryEnabled = true;
        if (prefDoc.exists) {
            const prefs = prefDoc.data();
            const masterEnabled = prefs.notificationsEnabled ?? true;
            if (!masterEnabled) return;

            // Map categories to preference keys
            const keyMap = {
                'appointments': 'notifyAppointments',
                'chat': 'notifyChat',
                'emergency': 'notifyEmergency',
                'dailyCare': 'notifyDailyCare'
            };

            const prefKey = keyMap[category];
            if (prefKey) {
                isCategoryEnabled = prefs[prefKey] ?? true;
            }
        }

        if (!isCategoryEnabled) {
            console.log(`Sekat: User ${userId} mematikan notifikasi kategori ${category}.`);
            return;
        }

        const message = {
            notification: { title: title, body: body },
            token: fcmToken,
            data: {
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                category: category
            }
        };

        await admin.messaging().send(message);
        console.log(`Berjaya: Notifikasi ${category} dihantar ke ${userId}`);

    } catch (error) {
        console.error('Ralat hantaran:', error);
    }
}

/**
 * TRIGGER: Peringatan Temu Janji (Berjalan jam 8 Pagi setiap hari)
 */
exports.appointmentReminderCron = functions.pubsub
    .schedule('0 8 * * *')
    .timeZone('Asia/Kuala_Lumpur')
    .onRun(async (context) => {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        const dateStr = tomorrow.toISOString().split('T')[0];

        const snapshot = await admin.firestore().collection('appointments')
            .where('appointmentDateString', '==', dateStr)
            .get();

        const promises = [];
        snapshot.forEach(doc => {
            const data = doc.data();
            promises.push(sendTargetedNotification(
                data.uid,
                "Peringatan Temu Janji Esok! 🏥",
                `Jangan lupa temu janji ${data.catName} di ${data.location} jam ${data.time}.`,
                'appointments'
            ));
        });

        return Promise.all(promises);
    });

/**
 * TRIGGER: Peringatan Tugasan Harian (Jam 7 Malam jika belum siap)
 */
exports.dailyTaskReminderCron = functions.pubsub
    .schedule('0 19 * * *')
    .timeZone('Asia/Kuala_Lumpur')
    .onRun(async (context) => {
        const users = await admin.firestore().collection('users').get();
        const promises = [];

        users.forEach(userDoc => {
            const data = userDoc.data();
            // Semak jika streak terakhir bukan hari ini (anggaran tugasan belum siap)
            const lastDate = data.lastStreakDate ? data.lastStreakDate.toDate() : null;
            const today = new Date();

            const isDoneToday = lastDate &&
                lastDate.getDate() === today.getDate() &&
                lastDate.getMonth() === today.getMonth() &&
                lastDate.getFullYear() === today.getFullYear();

            if (!isDoneToday) {
                promises.push(sendTargetedNotification(
                    userDoc.id,
                    "Tugasan Harian Belum Selesai! 🐱",
                    "Jangan biarkan si bulus menunggu. Selesaikan tugasan harian anda untuk kekalkan streak!",
                    'dailyCare'
                ));
            }
        });

        return Promise.all(promises);
    });

/**
 * TRIGGER: Amaran Kucing Hilang (Kawasan Berdekatan)
 */
exports.onLostCatAlert = functions.firestore.document('community_posts/{postId}')
    .onCreate(async (snapshot, context) => {
        const post = snapshot.data();
        if (post.category !== 'Lost & found' || post.status !== 'Lost') return null;

        // Dapatkan semua user berdekatan (Contoh ringkas: satu negeri/kawasan)
        // Dalam realiti, guna GeoFirestore untuk radius
        const users = await admin.firestore().collection('users').limit(100).get();

        const promises = [];
        users.forEach(userDoc => {
            if (userDoc.id !== post.ownerId) {
                promises.push(sendTargetedNotification(
                    userDoc.id,
                    "KECEMASAN KUCING HILANG! 😿",
                    `Bantu cari ${post.title}. Terakhir dilihat di ${post.locationLabel}.`,
                    'emergency'
                ));
            }
        });
        return Promise.all(promises);
    });

/**
 * TRIGGER: Peringatan Tugasan Harian (Jam 7 Malam jika belum siap)
 */
exports.dailyTaskReminderCron = functions.pubsub
    .schedule('0 19 * * *')
    .timeZone('Asia/Kuala_Lumpur')
    .onRun(async (context) => {
        const users = await admin.firestore().collection('users').get();
        const promises = [];

        users.forEach(userDoc => {
            const data = userDoc.data();
            // Semak jika streak terakhir bukan hari ini (anggaran tugasan belum siap)
            const lastDate = data.lastStreakDate ? data.lastStreakDate.toDate() : null;
            const today = new Date();

            const isDoneToday = lastDate &&
                lastDate.getDate() === today.getDate() &&
                lastDate.getMonth() === today.getMonth() &&
                lastDate.getFullYear() === today.getFullYear();

            if (!isDoneToday) {
                promises.push(sendTargetedNotification(
                    userDoc.id,
                    "Tugasan Harian Belum Selesai! 🐱",
                    "Jangan biarkan si bulus menunggu. Selesaikan tugasan harian anda untuk kekalkan streak!",
                    'dailyCare'
                ));
            }
        });

        return Promise.all(promises);
    });

/**
 * TRIGGER: Mesej Chat Baru
 */
exports.onNewChatMessage = functions.firestore.document('users/{userId}/chat_history/{sessionId}/messages/{messageId}')
    .onCreate(async (snapshot, context) => {
        const message = snapshot.data();
        const receiverId = context.params.userId;

        // Jangan hantar jika mesej dari diri sendiri (untuk AI chat, logic isMe biasanya true utk user)
        // Jika AI chat, AI menghantar dengan isMe = false.
        if (message.isMe === true) return null;

        return sendTargetedNotification(
            receiverId,
            "Mesej Baru 🐾",
            message.text.length > 50 ? message.text.substring(0, 50) + "..." : message.text,
            'chat'
        );
    });

/**
 * TRIGGER: Permintaan Purrmate (Friend Request)
 */
exports.onFriendRequest = functions.firestore.document('users/{userId}/pending_requests/{senderId}')
    .onCreate(async (snapshot, context) => {
        const request = snapshot.data();
        const receiverId = context.params.userId;

        return sendTargetedNotification(
            receiverId,
            "Permintaan Purrmate Baru! 🤝",
            `${request.fromName} ingin menjadi Purrmate anda.`,
            'chat' // Guna kategori chat/sosial
        );
    });
