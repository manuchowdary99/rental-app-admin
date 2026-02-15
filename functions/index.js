const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
  try {
    const token = data.token;
    const title = data.title;
    const body = data.body;

    if (!token) {
      throw new Error("FCM token is required");
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      token: token,
    };

    await admin.messaging().send(message);

    return { success: true };
  } catch (error) {
    console.error("Error sending notification:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Unable to send notification"
    );
  }
});
