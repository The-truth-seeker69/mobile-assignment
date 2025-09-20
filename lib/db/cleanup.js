// cleanup.js - Script to clear existing data before importing new structure
const admin = require("firebase-admin");
const fs = require("fs");

// Path to your service account key (download from Firebase Console > Project Settings > Service Accounts)
const serviceAccount = require("./serviceAccountKey.json");

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Helper function to delete all documents in a collection
async function deleteCollection(collectionPath) {
  const collectionRef = db.collection(collectionPath);
  const snapshot = await collectionRef.get();

  if (snapshot.empty) {
    console.log(`📭 Collection ${collectionPath} is already empty`);
    return;
  }

  console.log(
    `🗑️  Deleting ${snapshot.size} documents from ${collectionPath}...`
  );

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();
  console.log(`✅ Deleted all documents from ${collectionPath}`);
}

// Helper function to delete subcollections recursively
async function deleteSubcollections(collectionPath) {
  const collectionRef = db.collection(collectionPath);
  const snapshot = await collectionRef.get();

  for (const doc of snapshot.docs) {
    // Delete subcollections for each document
    const subcollections = await doc.ref.listCollections();

    for (const subcollection of subcollections) {
      console.log(
        `🗑️  Deleting subcollection ${collectionPath}/${doc.id}/${subcollection.id}...`
      );

      // Get all documents in the subcollection
      const subSnapshot = await subcollection.get();

      if (!subSnapshot.empty) {
        const batch = db.batch();
        subSnapshot.docs.forEach((subDoc) => {
          batch.delete(subDoc.ref);
        });
        await batch.commit();
        console.log(
          `✅ Deleted ${subSnapshot.size} documents from ${collectionPath}/${doc.id}/${subcollection.id}`
        );
      }
    }
  }
}

// Main cleanup function
async function cleanup() {
  console.log("🧹 Starting cleanup process...");

  try {
    // Delete chats collection and all its subcollections
    console.log("\n💬 Cleaning up chats collection...");
    await deleteSubcollections("chats");
    await deleteCollection("chats");

    // Delete other collections
    const collections = [
      "customers",
      "vehicles",
      "mechanics",
      "inventory",
      "jobs",
      "invoices",
      "requests",
    ];

    for (const collectionName of collections) {
      console.log(`\n📦 Cleaning up ${collectionName} collection...`);
      await deleteCollection(collectionName);
    }

    console.log("\n🎉 Cleanup completed successfully!");
    console.log(
      "💡 You can now run 'node seed.js' to import the new structure"
    );
  } catch (error) {
    console.error("❌ Error during cleanup:", error);
  }
}

cleanup();
