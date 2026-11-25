const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

// ✅ Trigger: whenever a new attendance record is created (punch in/out)
exports.sendPunchNotification = onDocumentCreated(
  "attendance/{attendanceId}",
  async (event) => {
    const record = event.data.data();
    if (!record) return;

    const {userName, punchType, userId} = record;
    const isPunchIn = punchType === "in";

    const title = isPunchIn ? "🟢 Punch In" : "🔴 Punch Out";
    const body = `${userName} has punched ${isPunchIn ? "in" : "out"}`;

    const db = getFirestore();
    const messaging = getMessaging();

    try {
      // 1️⃣ Notify all ADMINS
      const adminsSnapshot = await db
        .collection("users")
        .where("role", "==", "admin")
        .where("isActive", "==", true)
        .get();

      const adminTokens = [];
      adminsSnapshot.forEach((doc) => {
        const token = doc.data().fcmToken;
        if (token) adminTokens.push(token);
      });

      if (adminTokens.length > 0) {
        await messaging.sendEachForMulticast({
          tokens: adminTokens,
          notification: {title, body},
          android: {
            notification: {
              channelId: "techtracker_channel",
              color: "#D4AF37",
            },
          },
        });
      }

      // 2️⃣ Optional: notify the TECH themselves as a confirmation
      if (userId) {
        const userDoc = await db.collection("users").doc(userId).get();
        const userToken = userDoc.data()?.fcmToken;
        if (userToken) {
          await messaging.send({
            token: userToken,
            notification: {
              title: isPunchIn ? "✅ You're punched in" : "✅ You're punched out",
              body: isPunchIn
                ? "Have a great shift!"
                : "Thanks for your hard work today.",
            },
            android: {
              notification: {
                channelId: "techtracker_channel",
                color: "#D4AF37",
              },
            },
          });
        }
      }
    } catch (error) {
      console.error("Error sending punch notification:", error);
    }
  }
);