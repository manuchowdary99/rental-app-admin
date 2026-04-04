const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

const smtpConfig = functions.config().smtp || {};

const transporter = nodemailer.createTransport({
  host: smtpConfig.host,
  port: Number(smtpConfig.port || 587),
  secure: String(smtpConfig.secure || "false") === "true",
  auth:
    smtpConfig.user && smtpConfig.pass
      ? {
          user: smtpConfig.user,
          pass: smtpConfig.pass,
        }
      : undefined,
});

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

exports.sendQueuedMail = functions.firestore
  .document("mail/{mailId}")
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data() || {};
    const message = data.message || {};
    const toField = data.to;

    const recipients = Array.isArray(toField)
      ? toField.filter((value) => typeof value === "string" && value.trim())
      : typeof toField === "string" && toField.trim()
      ? [toField.trim()]
      : [];

    if (!smtpConfig.host || !smtpConfig.user || !smtpConfig.pass) {
      console.error("SMTP config is missing. Set functions.config().smtp values");
      await snapshot.ref.set(
        {
          delivery: {
            state: "failed",
            error: "SMTP configuration missing",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        },
        { merge: true }
      );
      return;
    }

    if (recipients.length === 0) {
      await snapshot.ref.set(
        {
          delivery: {
            state: "failed",
            error: "No recipients in mail.to",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        },
        { merge: true }
      );
      return;
    }

    try {
      const info = await transporter.sendMail({
        from: smtpConfig.from || smtpConfig.user,
        to: recipients.join(","),
        subject: message.subject || "Rental Subscription Update",
        text: message.text || "",
        html: message.html || undefined,
      });

      await snapshot.ref.set(
        {
          delivery: {
            state: "sent",
            messageId: info.messageId || null,
            recipients,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        },
        { merge: true }
      );
    } catch (error) {
      console.error("sendQueuedMail failed", error);
      await snapshot.ref.set(
        {
          delivery: {
            state: "failed",
            error: error && error.message ? error.message : String(error),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        },
        { merge: true }
      );
    }
  });

exports.autoExpireSubscriptions = functions.pubsub
  .schedule("every 24 hours")
  .timeZone("Asia/Kolkata")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const fields = ["endDate", "subscriptionExpiry", "expiryDate"];
    const processedIds = new Set();
    let updated = 0;

    for (const fieldName of fields) {
      const snapshot = await admin
        .firestore()
        .collection("subscriptions")
        .where(fieldName, "<", now)
        .where("status", "==", "active")
        .get();

      if (snapshot.empty) {
        continue;
      }

      let batch = admin.firestore().batch();
      let batchCount = 0;

      for (const doc of snapshot.docs) {
        if (processedIds.has(doc.id)) {
          continue;
        }
        processedIds.add(doc.id);
        batch.update(doc.ref, {
          status: "expired",
          subscriptionStatus: "expired",
          autoRenew: false,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        batchCount += 1;
        updated += 1;

        if (batchCount === 400) {
          await batch.commit();
          batch = admin.firestore().batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }
    }

    console.log(`autoExpireSubscriptions updated ${updated} subscription(s)`);
    return null;
  });
