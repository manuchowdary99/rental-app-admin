const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const collections = ["users", "orders", "kyc", "complaints"];

async function fixCollection(name) {
  console.log(`Checking ${name}...`);
  const snapshot = await db.collection(name).get();

  let fixed = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (!data.createdAt) {
      await doc.ref.update({
        createdAt: admin.firestore.Timestamp.now(),
      });
      fixed++;
    }
  }

  console.log(`Fixed ${fixed} documents in ${name}`);
}

async function run() {
  for (const col of collections) {
    await fixCollection(col);
  }
  console.log("DONE");
  process.exit();
}

run();
