import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/inventory_catalog.dart';

class FirestoreSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> seedAll() async {
    // Customers must be linked to real package documents: the package is
    // where their upstream cost comes from, and without it their entire
    // monthly bill is reported as profit.
    final packageIdsByName = await _seedPackages();
    await _seedCustomers(packageIdsByName);
    await _seedEmployees();
    await _seedInstallations();
    await _seedPayments();
    await _seedInventory();
    print('✅ All Firestore collections seeded successfully!');
  }

  // ─── PACKAGES ───────────────────────────────────────────
  static Future<Map<String, String>> _seedPackages() async {
    // connectionType must match a ConnectionType enum name ('wireless' /
    // 'opticalFibre'). Omitting it makes PackageModel default every package to
    // wireless, which silently mislabels the fibre tiers.
    final packages = [
      {
        'name': '5 Mbps',
        'speed': 5,
        'price': 1000,
        'costPrice': 600,
        'connectionType': 'wireless',
        'description': 'Basic Internet',
      },
      {
        'name': '10 Mbps',
        'speed': 10,
        'price': 1500,
        'costPrice': 900,
        'connectionType': 'wireless',
        'description': 'Standard Internet',
      },
      {
        'name': '20 Mbps',
        'speed': 20,
        'price': 2500,
        'costPrice': 1500,
        'connectionType': 'opticalFibre',
        'description': 'Unlimited Internet',
      },
      {
        'name': '50 Mbps',
        'speed': 50,
        'price': 4000,
        'costPrice': 2400,
        'connectionType': 'opticalFibre',
        'description': 'Fast Internet',
      },
      {
        'name': '100 Mbps',
        'speed': 100,
        'price': 6000,
        'costPrice': 3600,
        'connectionType': 'opticalFibre',
        'description': 'Ultra Fast Internet',
      },
    ];

    // Returns name -> generated document id, so customers can be linked to a
    // real package rather than an empty packageId.
    final idsByName = <String, String>{};
    for (final pkg in packages) {
      final ref = await _db.collection('packages').add({
        ...pkg,
        'createdAt': FieldValue.serverTimestamp(),
      });
      idsByName[pkg['name'] as String] = ref.id;
    }
    print('✅ packages seeded');
    return idsByName;
  }

  // ─── CUSTOMERS ──────────────────────────────────────────
  static Future<void> _seedCustomers(Map<String, String> packageIdsByName) async {
    // monthlyBill is intentionally independent of the package price — it is
    // the negotiated rate for this customer and stays editable. The packageId
    // supplies the upstream cost, so profit = monthlyBill - package.costPrice.
    // Ahmad Shah below is billed 3000 on a 2500 package: margin 1500, not 3000.
    final customers = [
      {
        'name': 'Ali Khan',
        'phone': '03001234567',
        'cnic': '12345-1234567-1',
        'address': 'Peshawar',
        'connectionType': 'wireless',
        'packageId': packageIdsByName['10 Mbps'] ?? '',
        'monthlyBill': 1500, // list price; margin 1500 - 900 = 600
        'status': 'active',
        'notes': '',
      },
      {
        'name': 'Ahmad Shah',
        'phone': '03119876543',
        'cnic': '54321-7654321-2',
        'address': 'Nowshera',
        'connectionType': 'fiber',
        'packageId': packageIdsByName['20 Mbps'] ?? '',
        'monthlyBill': 3000, // negotiated above list; margin 3000 - 1500 = 1500
        'status': 'active',
        'notes': '',
      },
    ];

    for (final customer in customers) {
      await _db.collection('customers').add({
        ...customer,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    print('✅ customers seeded');
  }

  // ─── EMPLOYEES ──────────────────────────────────────────
  static Future<void> _seedEmployees() async {
    final employees = [
      {
        'name': 'Bilal Ahmed',
        'phone': '03331112233',
        'designation': 'Technician',
        'status': 'active',
      },
      {
        'name': 'Usman Ali',
        'phone': '03214445566',
        'designation': 'Field Engineer',
        'status': 'active',
      },
    ];

    for (final emp in employees) {
      await _db.collection('employees').add({
        ...emp,
        'joinDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    print('✅ employees seeded');
  }

  // ─── INSTALLATIONS ──────────────────────────────────────
  static Future<void> _seedInstallations() async {
    final installations = [
      {
        'customerId': '',
        'customerName': 'Ali Khan',
        'connectionType': 'wireless',
        'assignedEmployeeId': '',
        'assignedEmployeeName': 'Bilal Ahmed',
        'installationCost': 3000,
        'status': 'completed',
        'remarks': 'Installation done successfully',
      },
      {
        'customerId': '',
        'customerName': 'Ahmad Shah',
        'connectionType': 'opticalFibre',
        'assignedEmployeeId': '',
        'assignedEmployeeName': 'Usman Ali',
        'installationCost': 8000,
        'status': 'pending',
        'remarks': '',
      },
    ];

    for (final inst in installations) {
      await _db.collection('installations').add({
        ...inst,
        'installationDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    print('✅ installations seeded');
  }

  // ─── PAYMENTS ───────────────────────────────────────────
  static Future<void> _seedPayments() async {
    final payments = [
      {
        'customerId': '',
        'customerName': 'Ali Khan',
        'billingMonth': '2025-01',
        'amount': 1500,
        'paymentMethod': 'cash',
        'status': 'paid',
        'notes': '',
      },
      {
        'customerId': '',
        'customerName': 'Ahmad Shah',
        'billingMonth': '2025-01',
        'amount': 3000,
        'paymentMethod': 'jazzcash',
        'status': 'unpaid',
        'notes': '',
      },
    ];

    for (final pay in payments) {
      await _db.collection('payments').add({
        ...pay,
        'paymentDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    print('✅ payments seeded');
  }

  // ─── INVENTORY ──────────────────────────────────────────
  // Seeded from the shared client-supplied catalog (see inventory_catalog.dart),
  // which also powers the "pick from catalog" picker when adding items in-app.
  static Future<void> _seedInventory() async {
    for (final entry in kInventoryCatalog) {
      await _db.collection('inventory').add({
        'name': entry.name,
        'category': entry.category.name,
        'connectionType': entry.connectionType.name,
        'unit': entry.unit,
        'quantityInStock': entry.quantityInStock,
        'reorderLevel': entry.reorderLevel,
        'unitCost': entry.unitCost,
        'supplier': null,
        'notes': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    print('✅ inventory seeded');
  }
}
