// seed_packages.js
//
// Terminal seeder for the `packages` collection (NASR ISP admin panel).
//
// - Existing packages are matched by connectionType + speedMbps, so document IDs
//   stay the same. Only price, costPrice and updatedAt change on those docs.
// - Missing packages are created in the same shape as your export.
// - Packages not in the list (6, 9, 25 Mbps, "Carporate Both") are left untouched.
// - Dry run by default. Add --apply to actually write.
//
// Usage:
//   node seed_packages.js            # preview only
//   node seed_packages.js --apply    # write to Firestore
//
// Needs ./serviceAccountKey.json (or set GOOGLE_APPLICATION_CREDENTIALS).

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const path = require('path');

const APPLY = process.argv.includes('--apply');

const keyPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(__dirname, 'serviceAccountKey.json');

initializeApp({ credential: cert(require(keyPath)) });
const db = getFirestore();

// speedMbps, costPrice (vendor panel), wireless sell price, fibre sell price
const TIERS = [
  { speedMbps: 8,  costPrice: 1115, wireless: 2500,  fibre: 1500 },
  { speedMbps: 10, costPrice: 1239, wireless: 3000,  fibre: 2000 },
  { speedMbps: 15, costPrice: 1398, wireless: 3500,  fibre: 2500 },
  { speedMbps: 20, costPrice: 1512, wireless: 4250,  fibre: 3000 },
  { speedMbps: 30, costPrice: 1825, wireless: 6000,  fibre: 4000 },
  { speedMbps: 50, costPrice: 3076, wireless: 10000, fibre: 6000 },
];

async function main() {
  const col = db.collection('packages');
  const snapshot = await col.get();

  // Index existing docs by "<connectionType>_<speedMbps>"
  const existing = {};
  snapshot.forEach((doc) => {
    const d = doc.data();
    const key = `${d.connectionType}_${d.speedMbps}`;
    (existing[key] = existing[key] || []).push(doc);
  });

  const batch = db.batch();
  const touched = new Set();
  let updated = 0;
  let created = 0;

  function upsert(tier, type, price) {
    const key = `${type}_${tier.speedMbps}`;
    const docs = existing[key];

    if (docs && docs.length) {
      for (const doc of docs) {
        const old = doc.data();
        console.log(
          `UPDATE ${doc.id} (${old.name}): price ${old.price} -> ${price}, cost ${old.costPrice} -> ${tier.costPrice}`
        );
        batch.update(doc.ref, {
          price,
          costPrice: tier.costPrice,
          updatedAt: FieldValue.serverTimestamp(),
        });
        updated++;
      }
      touched.add(key);
    } else {
      const isWireless = type === 'wireless';
      const name = `${tier.speedMbps} Mbps ${isWireless ? 'Wireless' : 'Fibre'}`;
      const description = `${tier.speedMbps} Mbps ${isWireless ? 'Wireless' : 'Optical Fibre'}`;
      console.log(`CREATE ${name}: price ${price}, cost ${tier.costPrice}`);
      batch.set(col.doc(), {
        name,
        description,
        speedMbps: tier.speedMbps,
        connectionType: type,
        price,
        costPrice: tier.costPrice,
        isActive: true,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      created++;
    }
  }

  for (const t of TIERS) {
    upsert(t, 'wireless', t.wireless);
    upsert(t, 'opticalFibre', t.fibre);
  }

  for (const [key, docs] of Object.entries(existing)) {
    if (!touched.has(key)) {
      for (const doc of docs) {
        console.log(`LEFT UNCHANGED ${doc.id} (${doc.data().name})`);
      }
    }
  }

  console.log(
    `\n${updated} to update, ${created} to create${APPLY ? '' : ' (DRY RUN, nothing written)'}`
  );

  if (!APPLY) {
    console.log('Run again with --apply to write these changes.');
    return;
  }

  await batch.commit();
  console.log('Seed complete.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
