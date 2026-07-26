/**
 * Creates the 12 package documents that the customer migration references.
 *
 * WHY THIS EXISTS
 * ---------------
 * import-customers.js writes a `packageId` on every customer, taken from the
 * "Package ID Mapping" sheet. Those are explicit Firestore document ids
 * (e.g. wAlK3UX93H76ROODPYoL) — but nothing ever created the documents they
 * point at. FirestoreSeeder makes packages with auto-generated ids, which can
 * never match.
 *
 * The consequence: every customer's package lookup fails, the upstream cost
 * falls back to 0, and the app reports each customer's ENTIRE monthly bill as
 * profit. Run this BEFORE import-customers.js.
 *
 * Uses .set() with an explicit id, so it is idempotent — re-running updates
 * the same 12 documents rather than creating duplicates.
 *
 * Usage:  node import-packages.js
 */

const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const serviceAccount = require("./serviceAccountKey.json");

initializeApp({ credential: cert(serviceAccount) });

const db = getFirestore();

/**
 * The 12 packages, keyed by the exact document id the customer records expect.
 *
 * `price`  — the list price. Verified against the migration data: every
 *            customer on a given package has an identical monthlyBill, so the
 *            observed bill IS the list price. The count of customers currently
 *            on each package is noted alongside.
 *
 * `costPrice` — what NASR pays upstream per subscriber per month. THIS IS THE
 *            NUMBER THAT MAKES PROFIT REAL: profit = monthlyBill - costPrice.
 *            It is not present anywhere in the migration workbook, so it must
 *            be supplied here. A package left at 0 is treated by the app as
 *            "cost unknown" and is flagged in the UI rather than silently
 *            reporting the full bill as margin.
 */
const PACKAGES = [
  // ── Wireless ──────────────────────────────────────────────────────────
  { id: "wAlK3UX93H76ROODPYoL", name: "9 Mbps",  speedMbps: 9,  connectionType: "wireless",     price: 3000,  costPrice: 0 }, // 26 customers
  { id: "azQ61HJUIF5qNzXeOXBk", name: "10 Mbps", speedMbps: 10, connectionType: "wireless",     price: 3000,  costPrice: 0 }, // 17 customers
  { id: "Ww1iXVrUjcUQSEArNk87", name: "15 Mbps", speedMbps: 15, connectionType: "wireless",     price: 3500,  costPrice: 0 }, // 23 customers
  { id: "rEPxRwtvC98YMnqICU0N", name: "20 Mbps", speedMbps: 20, connectionType: "wireless",     price: 4250,  costPrice: 0 }, // 22 customers
  { id: "SDXnH4GqU04WdDEfg7hz", name: "25 Mbps", speedMbps: 25, connectionType: "wireless",     price: 5000,  costPrice: 0 }, // 3 customers
  { id: "6b7cwHMAmjYoCZNbOQgF", name: "50 Mbps", speedMbps: 50, connectionType: "wireless",     price: 0,     costPrice: 0 }, // no customers — price unknown

  // ── Optical fibre ─────────────────────────────────────────────────────
  { id: "wYSXzKizjvOFF8gDKjTc", name: "9 Mbps",  speedMbps: 9,  connectionType: "opticalFibre", price: 2500,  costPrice: 0 }, // 2 customers
  { id: "vIasK1Q8I4B9T4Vbwhwq", name: "10 Mbps", speedMbps: 10, connectionType: "opticalFibre", price: 2500,  costPrice: 0 }, // 4 customers
  { id: "r49J4u8Qum9ZN2Oa3k81", name: "15 Mbps", speedMbps: 15, connectionType: "opticalFibre", price: 0,     costPrice: 0 }, // no customers — price unknown
  { id: "LqSeGx8gGA9iuGACLU9E", name: "20 Mbps", speedMbps: 20, connectionType: "opticalFibre", price: 3250,  costPrice: 0 }, // 1 customer
  { id: "eqvDeS5osbyF3y50stJT", name: "25 Mbps", speedMbps: 25, connectionType: "opticalFibre", price: 0,     costPrice: 0 }, // no customers — price unknown
  { id: "PnYeQFXSoyoLjHiPTK3I", name: "50 Mbps", speedMbps: 50, connectionType: "opticalFibre", price: 10000, costPrice: 0 }, // 1 customer
];

async function importPackages() {
  console.log(`Writing ${PACKAGES.length} packages...`);

  const batch = db.batch();

  for (const pkg of PACKAGES) {
    const { id, ...data } = pkg;

    batch.set(
      db.collection("packages").doc(id),
      {
        ...data,
        description: `${data.name} ${
          data.connectionType === "wireless" ? "Wireless" : "Optical Fibre"
        }`,
        isActive: true,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      // merge: keeps any field a human has since edited in the app that this
      // script does not know about.
      { merge: true }
    );
  }

  await batch.commit();

  const unpriced = PACKAGES.filter((p) => !p.costPrice);

  console.log("");
  console.log("=================================");
  console.log("PACKAGE IMPORT COMPLETED");
  console.log("=================================");
  console.log(`Packages written: ${PACKAGES.length}`);

  if (unpriced.length) {
    console.log("");
    console.log(`WARNING: ${unpriced.length} package(s) have costPrice = 0.`);
    console.log("Profit for their subscribers will equal the FULL monthly");
    console.log("bill, and the app will flag them as 'no package cost'.");
    console.log("Set costPrice in PACKAGES above and re-run:");
    unpriced.forEach((p) =>
      console.log(`  - ${p.name} (${p.connectionType})`)
    );
  }

  console.log("=================================");
}

importPackages()
  .then(() => {
    console.log("Package import finished successfully.");
    process.exit(0);
  })
  .catch((error) => {
    console.error("Package import failed:");
    console.error(error);
    process.exit(1);
  });
