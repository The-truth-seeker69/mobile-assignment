// seed.js
const admin = require("firebase-admin");
const fs = require("fs");

// Path to your service account key (download from Firebase Console > Project Settings > Service Accounts)
const serviceAccount = require("./serviceAccountKey.json");

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Load seed data
const seedData = JSON.parse(fs.readFileSync("lib/db/seed.json", "utf8"));

// Helper function to write each collection
async function importData() {
  console.log("🚀 Starting data import...");

  for (const [collectionName, documents] of Object.entries(seedData)) {
    console.log(`\n📁 Processing collection: ${collectionName}`);

    if (collectionName === "chats") {
      // Handle chats collection with nested structure
      console.log("💬 Processing chats collection with nested structure...");

      for (const [customerId, customerData] of Object.entries(documents)) {
        console.log(`\n👤 Processing customer: ${customerId}`);

        // Create customer document (empty document to hold subcollections)
        await db.collection("chats").doc(customerId).set({});
        console.log(`✅ Created chats/${customerId}`);

        // Handle messages collection
        if (customerData.messages) {
          console.log(`📝 Processing messages for ${customerId}...`);

          for (const [messageId, messageData] of Object.entries(
            customerData.messages
          )) {
            if (messageId === "documents") {
              console.log(`📄 Processing documents for ${customerId}...`);

              // Create documents document (empty document to hold subcollections)
              await db
                .collection("chats")
                .doc(customerId)
                .collection("messages")
                .doc("documents")
                .set({});
              console.log(`✅ Created chats/${customerId}/messages/documents`);

              // Handle items collection
              if (messageData.items) {
                console.log(`📋 Processing items for ${customerId}...`);

                for (const [itemId, itemData] of Object.entries(
                  messageData.items
                )) {
                  await db
                    .collection("chats")
                    .doc(customerId)
                    .collection("messages")
                    .doc("documents")
                    .collection("items")
                    .doc(itemId)
                    .set(itemData);
                  console.log(
                    `✅ Imported chats/${customerId}/messages/documents/items/${itemId}`
                  );
                }
              }
            }
          }
        }
      }
    } else {
      // Handle other collections normally
      console.log(`📦 Processing regular collection: ${collectionName}`);

      for (const [docId, data] of Object.entries(documents)) {
        await db.collection(collectionName).doc(docId).set(data);
        console.log(`✅ Imported ${collectionName}/${docId}`);
      }
    }
  }
  console.log("🎉 All data imported successfully!");
}

importData().catch(console.error);
