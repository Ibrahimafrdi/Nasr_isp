// Usage:  node import-customers.js            -> DRY RUN (writes nothing)
//         node import-customers.js --commit   -> writes new customers
// Needs: serviceAccountKey.json and customers-to-import.json in the same folder.
const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const fs = require("fs");

const COMMIT = process.argv.includes("--commit");
const HOLD_CONFLICTS = false; // false = the 9 usernames where Jazz and NASR disagree use the Jazz details
const FIBER_USERNAMES = []; // docIds (e.g. "javid069_frontierbb9") that are fiber. Everyone else = wireless.

initializeApp({ credential: cert(require("./serviceAccountKey.json")) });
const db = getFirestore();
const rows = JSON.parse(fs.readFileSync("./customers-to-import.json", "utf8"));

const num = (v) => (typeof v === "number" ? v : parseFloat(String(v).replace(/[^\d.]/g, "")));
const pick = (d, re) => Object.keys(d).find((k) => re.test(k));

async function loadPackages() {
  const snap = await db.collection("packages").get();
  const table = {};
  for (const doc of snap.docs) {
    const d = doc.data();
    const kSpeed = pick(d, /speed|mbps/i), kType = pick(d, /type|categ/i);
    const kPrice = ["sellPrice", "price", "sellingPrice", "monthlyPrice"].find((k) => k in d) || pick(d, /sell|price/i);
    if (!kSpeed || !kType || !kPrice) {
      console.error("Cannot read this package, please send it to me:", doc.id, d);
      process.exit(1);
    }
    const type = /fib/i.test(String(d[kType])) ? "fiber" : /wire/i.test(String(d[kType])) ? "wireless" : null;
    if (!type) continue; // e.g. "Corporate Both"
    const key = `${type}:${num(d[kSpeed])}`;
    if (table[key]) { console.error("Two packages for", key, "- stopping."); process.exit(1); }
    table[key] = { id: doc.id, price: num(d[kPrice]), speed: num(d[kSpeed]), type };
  }
  return table;
}

(async () => {
  const pkgs = await loadPackages();
  console.log("\nPackages found:");
  Object.entries(pkgs).sort().forEach(([k, p]) => console.log(`  ${k.padEnd(14)} ${String(p.price).padStart(6)}  ${p.id}`));

  const toCreate = [], skipped = [], held = [];
  for (const r of rows) {
    if (HOLD_CONFLICTS && r.conflict) { held.push([r.username, "Jazz and NASR disagree - check which is right"]); continue; }
    const type = FIBER_USERNAMES.includes(r.docId) ? "fiber" : "wireless";
    const pkg = pkgs[`${type}:${r.mappedSpeed}`];
    if (!pkg) { held.push([r.username, `no ${type} ${r.mappedSpeed} Mbps package`]); continue; }
    if ((await db.collection("customers").doc(r.docId).get()).exists) { skipped.push(r.username); continue; }
    const notes = [`Username: ${r.username}`, `Panel: ${r.panel}`, r.ip ? `IP: ${r.ip}` : null,
      r.speed !== r.mappedSpeed ? `Old plan ${r.speed} Mbps, mapped to ${r.mappedSpeed} Mbps` : null].filter(Boolean).join("; ");
    toCreate.push({
      id: r.docId,
      data: {
        name: r.name, phone: "", cnic: "", address: "", connectionType: type,
        packageId: pkg.id, monthlyBill: pkg.price, status: "active", notes,
        joinDate: null,
        nextDueDate: Timestamp.fromDate(new Date(`${r.expiry}T00:00:00+05:00`)),
        createdAt: FieldValue.serverTimestamp(),
      },
    });
  }

  console.log(`\nTo create: ${toCreate.length}   Already exist (skipped): ${skipped.length}   Held back: ${held.length}`);
  if (held.length) { console.log("\nHeld back:"); held.forEach(([u, why]) => console.log(`  ${u} - ${why}`)); }
  console.log("\nFirst 5 to create:"); toCreate.slice(0, 5).forEach((c) => console.log(" ", c.id, c.data.name, c.data.monthlyBill, c.data.notes));

  if (!COMMIT) return console.log("\nDRY RUN only. Nothing written. Run with --commit to upload.");
  let batch = db.batch(), n = 0;
  for (const c of toCreate) {
    batch.create(db.collection("customers").doc(c.id), c.data); // create() fails if it exists: never overwrites
    if (++n % 400 === 0) { await batch.commit(); batch = db.batch(); }
  }
  await batch.commit();
  console.log(`\nDone. Created ${toCreate.length} customers.`);
})();
