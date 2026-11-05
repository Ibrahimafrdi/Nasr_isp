
const fs = require("fs");

const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

const serviceAccount = require("./serviceAccountKey.json.json");

initializeApp({
    credential: cert(serviceAccount),
});


const db = getFirestore();

async function exportCollection() {
    const collectionName = "customers"; // Change this
    const snapshot = await db.collection(collectionName).get();

    const documents = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
    }));

    // Export JSON
    fs.writeFileSync(
        `${collectionName}.json`,
        JSON.stringify(documents, null, 2)
    );

    // Export CSV
    const fields = [
        "id",
        ...new Set(documents.flatMap((doc) => Object.keys(doc))),
    ];

    const escapeCSV = (value) => {
        const text =
            value == null
                ? ""
                : typeof value === "object"
                    ? JSON.stringify(value)
                    : String(value);

        return `"${text.replace(/"/g, '""')}"`;
    };

    const csv = [
        fields.map(escapeCSV).join(","),
        ...documents.map((doc) =>
            fields
                .map((field) => escapeCSV(doc[field]))
                .join(",")
        ),
    ].join("\r\n");

    fs.writeFileSync(`${collectionName}.csv`, csv, "utf8");

    console.log(`Exported ${documents.length} documents.`);
    console.log(`Created ${collectionName}.json and ${collectionName}.csv`);
}

exportCollection().catch(console.error);
