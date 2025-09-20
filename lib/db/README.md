# Database Setup Guide

This directory contains scripts to set up your Firestore database with the correct structure for the Job Management for Workshop Manager app.

## Files

- `seed.json` - Contains all the sample data
- `seed.js` - Script to import data into Firestore with correct nested structure
- `cleanup.js` - Script to clear existing data before importing new structure
- `serviceAccountKey.json` - Your Firebase service account key (not included in repo for security)

## Prerequisites

1. **Node.js** installed on your system
2. **Firebase project** set up
3. **Service Account Key** downloaded from Firebase Console

### Getting Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings (gear icon) > Service Accounts
4. Click "Generate new private key"
5. Download the JSON file and rename it to `serviceAccountKey.json`
6. Place it in this directory (`lib/db/`)

## Installation

```bash
# Install required packages
npm init -y
npm install firebase-admin
```

## Usage

### Option 1: Clean Import (Recommended)

```bash
# 1. Clear existing data
node cleanup.js

# 2. Import new structure
node seed.js
```

### Option 2: Direct Import

```bash
# Import data directly (may cause conflicts if data exists)
node seed.js
```

## Database Structure

The script creates the following structure:

```
chats (collection)
├── cust001 (document)
│   └── messages (collection)
│       └── documents (document)
│           └── items (collection)
│               ├── T5VpetQaXAIwbp8hW51H (document)
│               │   ├── type: "text"
│               │   ├── text: "Hello John, your vehicle is ready for pickup."
│               │   ├── sender: "staff"
│               │   └── timestamp: "2025-09-18T12:00:00Z"
│               ├── V66g69ZvDiriUFkfgwhE (document)
│               │   ├── type: "image"
│               │   ├── fileName: "scaled_e2241e2a-386a-4f48-bafd-..."
│               │   ├── localPath: "/data/user/0/com.example.assignment/app_flutter/..."
│               │   ├── mimeType: "image/jpeg"
│               │   ├── sender: "staff"
│               │   └── timestamp: "2025-09-18T12:05:00Z"
│               └── ... (more message documents)
└── cust002 (document)
    └── messages (collection)
        └── documents (document)
            └── items (collection)
                ├── cust002_msg1 (document)
                └── ... (more message documents)

customers (collection)
├── cust001 (document)
│   ├── name: "John Doe"
│   ├── phone: "+60123456789"
│   ├── email: "ngjw-wm22@student.tarc.edu.my"
│   ├── address: "123 Main St, Kuala Lumpur"
│   ├── imagePath: "alvin.jpg"
│   └── vehicles: ["veh001"]
└── cust002 (document)
    └── ... (customer data)

vehicles (collection)
├── veh001 (document)
│   ├── customerId: "cust001"
│   ├── make: "Toyota"
│   ├── model: "Corolla"
│   ├── year: 2020
│   ├── plateNo: "WWW 888"
│   ├── vin: "JT12345ABC67890"
│   └── imagePath: "corolla.jpeg"
└── ... (more vehicles)

jobs (collection)
├── job001 (document)
│   ├── vehicleId: "veh001"
│   ├── mechanicId: "mech002"
│   ├── status: "assigned"
│   ├── scheduledDate: "2025-09-15"
│   ├── completionDate: null
│   ├── description: "Brake pad replacement"
│   ├── partsUsed: ["part001"]
│   ├── mileage: 15000
│   └── notes: "Used synthetic oil, but the oil is not really good"
└── ... (more jobs)

mechanics (collection)
├── mech001 (document)
│   ├── name: "Ali Bin Omar"
│   ├── specialization: "Engine Repair"
│   └── availability: true
└── ... (more mechanics)

inventory (collection)
├── IT002 (document)
│   ├── category: "Brake"
│   ├── name: "Brake Pad"
│   ├── quantity: 5
│   ├── supplier: "toyota"
│   └── ... (inventory data)
└── ... (more inventory items)

invoices (collection)
├── inv001 (document)
│   ├── jobId: "job002"
│   ├── customerId: "cust002"
│   ├── dateIssued: "2025-09-12"
│   ├── totalAmount: 220.0
│   ├── status: "paid"
│   └── ... (invoice data)
└── ... (more invoices)

requests (collection)
├── RQ001 (document)
│   ├── itemId: "IT002"
│   ├── quantity: 3
│   └── notes: "Needed urgently for upcoming job"
└── ... (more requests)
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Make sure your service account key has the correct permissions
2. **Collection Not Found**: Run the cleanup script first to ensure a clean state
3. **Import Errors**: Check that your `serviceAccountKey.json` is in the correct location

### Verification

After running the import, check your Firestore console to verify the structure matches the expected hierarchy.

## Security Note

⚠️ **Never commit `serviceAccountKey.json` to version control!** Add it to your `.gitignore` file.

```gitignore
lib/db/serviceAccountKey.json
```
