import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/inventory_catalog.dart';

class FirestoreSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> seedAll() async {
    await _seedPackages();
    await _seedCustomers();
    await _seedEmployees();
    await _seedInstallations();
    await _seedPayments();
    await _seedInventory();
    print('✅ All Firestore collections seeded successfully!');
  }

  // ─── PACKAGES ───────────────────────────────────────────
  static Future<void> _seedPackages() async {
    final packages = [
      {
        'name': '5 Mbps',
        'speed': 5,
        'price': 1000,
        'costPrice': 600,
        'description': 'Basic Internet',
      },
      {
        'name': '10 Mbps',
        'speed': 10,
        'price': 1500,
        'costPrice': 900,
        'description': 'Standard Internet',
      },
      {
        'name': '20 Mbps',
        'speed': 20,
        'price': 2500,
        'costPrice': 1500,
        'description': 'Unlimited Internet',
      },
      {
        'name': '50 Mbps',
        'speed': 50,
        'price': 4000,
        'costPrice': 2400,
        'description': 'Fast Internet',
      },
      {
        'name': '100 Mbps',
        'speed': 100,
        'price': 6000,
        'costPrice': 3600,
        'description': 'Ultra Fast Internet',
      },
    ];

    for (final pkg in packages) {
      await _db.collection('packages').add({
        ...pkg,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    print('✅ packages seeded');
  }

  // ─── CUSTOMERS ──────────────────────────────────────────
  static Future<void> _seedCustomers() async {
    final customers = [
      {
        'name': 'Ali Khan',
        'phone': '03001234567',
        'cnic': '12345-1234567-1',
        'address': 'Peshawar',
        'connectionType': 'wireless',
        'packageId': '',
        'installationCost': 3000,
        'monthlyBill': 1500,
        'status': 'active',
        'notes': '',
      },
      {
        'name': 'Ahmad Shah',
        'phone': '03119876543',
        'cnic': '54321-7654321-2',
        'address': 'Nowshera',
        'connectionType': 'fiber',
        'packageId': '',
        'installationCost': 8000,
        'monthlyBill': 3000,
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
