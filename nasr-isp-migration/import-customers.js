const { initializeApp, cert } = require("firebase-admin/app");
const {
    getFirestore,
    FieldValue,
    Timestamp,
} = require("firebase-admin/firestore");

const XLSX = require("xlsx");
const path = require("path");

const serviceAccount = require("./serviceAccountKey.json");

initializeApp({
    credential: cert(serviceAccount),
});

const db = getFirestore();

const excelPath = path.join(
    __dirname,
    "NASR_ISP_Firebase_Migration_READY_99_CUSTOMERS.xlsx"
);

const workbook = XLSX.readFile(excelPath);

const sheet = workbook.Sheets["Firestore Customers"];

if (!sheet) {
    throw new Error(
        'Sheet "Firestore Customers" was not found in the Excel file.'
    );
}

const rows = XLSX.utils.sheet_to_json(sheet, {
    defval: "",
});

function parseDate(value) {
    if (!value || value === "") {
        return null;
    }

    const date = new Date(value);

    if (isNaN(date.getTime())) {
        return null;
    }

    return Timestamp.fromDate(date);
}

function cleanString(value) {
    if (value === null || value === undefined) {
        return "";
    }

    return String(value).trim();
}

async function importCustomers() {
    console.log(`Found ${rows.length} customers in Excel.`);

    if (rows.length !== 99) {
        console.warn(
            `WARNING: Expected 99 customers, but found ${rows.length}.`
        );
    }

    let batch = db.batch();
    let batchCount = 0;
    let imported = 0;

    for (const row of rows) {
        const documentId = cleanString(row["Document ID"]);

        if (!documentId) {
            console.warn(
                "Skipping customer without Document ID:",
                row["name"]
            );
            continue;
        }

        const customerData = {
            name: cleanString(row["name"]),
            phone: cleanString(row["phone"]),
            cnic: cleanString(row["cnic"]),
            address: cleanString(row["address"]),

            connectionType: cleanString(
                row["connectionType"]
            ),

            packageId: cleanString(
                row["packageId"]
            ),

            monthlyBill:
                Number(row["monthlyBill"]) || 0,

            status: cleanString(
                row["status"]
            ),

            notes: cleanString(
                row["notes"]
            ),

            createdAt:
                FieldValue.serverTimestamp(),

            joinDate: null,

            nextDueDate:
                parseDate(row["nextDueDate"]),
        };

        const customerRef = db
            .collection("customers")
            .doc(documentId);

        batch.set(
            customerRef,
            customerData
        );

        imported++;
        batchCount++;

        if (batchCount === 400) {
            await batch.commit();

            console.log(
                `Committed ${batchCount} customers.`
            );

            batch = db.batch();
            batchCount = 0;
        }
    }

    if (batchCount > 0) {
        await batch.commit();

        console.log(
            `Committed final ${batchCount} customers.`
        );
    }

    console.log("");
    console.log(
        "================================="
    );
    console.log(
        "CUSTOMER IMPORT COMPLETED"
    );
    console.log(
        "================================="
    );
    console.log(
        `Customers imported: ${imported}`
    );
    console.log(
        "Installations created: 0"
    );
    console.log(
        "================================="
    );
}

importCustomers()
    .then(() => {
        console.log(
            "Migration finished successfully."
        );

        process.exit(0);
    })
    .catch((error) => {
        console.error(
            "Migration failed:"
        );

        console.error(error);

        process.exit(1);
    });