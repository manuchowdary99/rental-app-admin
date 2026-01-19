const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function migrateAllRentals() {
  const rentalsSnap = await db.collection("rentals").get();

  if (rentalsSnap.empty) {
    console.log("ℹ️ No rentals found");
    return;
  }

  let migratedCount = 0;
  let skippedCount = 0;
  let errorCount = 0;

  for (const doc of rentalsSnap.docs) {
    const rentalId = doc.id;
    const rental = doc.data();

    // 🔒 Skip if already migrated
    const orderRef = db.collection("orders").doc(rentalId);
    const orderSnap = await orderRef.get();

    if (orderSnap.exists) {
      console.log(`⏭ Skipped ${rentalId} (order already exists)`);
      skippedCount++;
      continue;
    }

    // 🚨 Hard validation
    if (!rental.itemId) {
      console.log(`⚠️ Skipped ${rentalId} (missing itemId)`);
      skippedCount++;
      continue;
    }

    const productName =
      rental.itemName && typeof rental.itemName === "string"
        ? rental.itemName
        : "Unknown Item";

    try {
      // 1️⃣ Order doc
      await orderRef.set({
        orderNumber: rental.id ?? rentalId,
        orderType: "rental",
        orderStatus: rental.status ?? "unknown",
        paymentStatus: "unknown",

        totalAmount: rental.totalAmount ?? 0,
        finalAmount: rental.totalAmount ?? 0,
        depositAmount: null,
        taxAmount: 0,

        userId: rental.renterId ?? null,

        createdAt:
          rental.createdAt ?? admin.firestore.FieldValue.serverTimestamp(),
        updatedAt:
          rental.updatedAt ?? admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2️⃣ Item snapshot
      await orderRef.collection("items").add({
        productId: rental.itemId,
        productName: productName,

        quantity: 1,
        unitPrice: rental.totalAmount ?? 0,
        totalPrice: rental.totalAmount ?? 0,

        rentalStartDate: rental.startDate ?? null,
        rentalEndDate: rental.endDate ?? null,

        createdAt:
          rental.createdAt ?? admin.firestore.FieldValue.serverTimestamp(),
      });

      // 3️⃣ Rental lifecycle
      await orderRef.collection("rentals").doc("details").set({
        depositAmount: null,

        startDate: rental.startDate ?? null,
        endDate: rental.endDate ?? null,

        returnStatus: "pending",
        returnedAt: null,

        refundStatus: "pending",
        refundedAt: null,
      });

      migratedCount++;
      console.log(`✅ Migrated ${rentalId}`);
    } catch (err) {
      errorCount++;
      console.error(`❌ Failed ${rentalId}:`, err.message);
    }
  }

  console.log("\n🚀 Migration completed");
  console.log(`✔ Migrated: ${migratedCount}`);
  console.log(`⏭ Skipped: ${skippedCount}`);
  console.log(`❌ Errors: ${errorCount}`);
}

migrateAllRentals()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
