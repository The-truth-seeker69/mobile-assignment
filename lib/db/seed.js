// seed.js
const admin = require("firebase-admin");
const fs = require("fs");

// Path to your service account key (download from Firebase Console > Project Settings > Service Accounts)
const serviceAccount = require("./serviceAccountKey.json");

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Load seed data
const seedData = JSON.parse(fs.readFileSync("lib/db/seed.json", "utf8"));

// Helper function to write each collection
async function importData() {
  for (const [collectionName, documents] of Object.entries(seedData)) {
    for (const [docId, data] of Object.entries(documents)) {
      await db.collection(collectionName).doc(docId).set(data);
      console.log(`✅ Imported ${collectionName}/${docId}`);
    }
  }
  console.log("🎉 All data imported successfully!");
}

importData().catch(console.error);
