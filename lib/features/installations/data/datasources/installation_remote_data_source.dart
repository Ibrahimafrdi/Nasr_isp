import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/installations/data/models/installation_model.dart';

abstract class InstallationRemoteDataSource {
  Future<void> addInstallation(InstallationModel installation);
  Future<List<InstallationModel>> getInstallations({
    String? status,
    String? connectionType,
    String? employeeId,
    String? searchQuery,
  });
  Future<List<InstallationModel>> getInstallationsByCustomer(String customerId);
  Future<void> updateInstallation(InstallationModel installation);
  Future<void> deleteInstallation(String id);
}

class InstallationRemoteDataSourceImpl implements InstallationRemoteDataSource {
  final FirebaseFirestore _firestore;

  InstallationRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('installations');

  // Syncs the customer's status/installationCost and decrements inventory
  // stock (with stockOut movement docs) for a job transitioning to
  // Completed. All transaction reads (customer doc + every inventory item
  // doc) are gathered up front and validated before any writes are issued —
  // Firestore transactions require every read to precede every write, so
  // reads and writes must never be interleaved in the loop below.
  Future<void> _syncCustomerAndInventoryForCompletion(
    Transaction transaction,
    InstallationModel installation,
  ) async {
    // ---- Reads ----
    final customerDocRef = _firestore.collection('customers').doc(installation.customerId);
    final customerDoc = await transaction.get(customerDocRef);

    final items = installation.itemsUsed ?? const [];
    final itemDocRefs = <DocumentReference>[];
    final itemSnapshots = <DocumentSnapshot>[];
    for (final item in items) {
      final itemDocRef = _firestore.collection('inventory').doc(item.inventoryItemId);
      itemDocRefs.add(itemDocRef);
      itemSnapshots.add(await transaction.get(itemDocRef));
    }

    for (var i = 0; i < items.length; i++) {
      if (!itemSnapshots[i].exists) {
        throw Exception('Inventory item ${items[i].itemName} does not exist.');
      }
      final itemData = itemSnapshots[i].data() as Map<String, dynamic>? ?? {};
      final quantityInStock = (itemData['quantityInStock'] as num?)?.toInt() ?? 0;
      if (quantityInStock < items[i].quantity) {
        throw Exception(
          'Insufficient stock for ${items[i].itemName}. Available: $quantityInStock, Required: ${items[i].quantity}',
        );
      }
    }

    // ---- Writes (only after every read above has completed) ----
    if (customerDoc.exists) {
      final customerData = customerDoc.data() as Map<String, dynamic>? ?? {};
      final currentCost = (customerData['installationCost'] as num?)?.toDouble() ?? 0.0;

      final Map<String, dynamic> customerUpdates = {};
      if (currentCost == 0.0) {
        customerUpdates['installationCost'] = installation.installationCost;
      }
      final currentStatus = customerData['status'] as String? ?? '';
      if (currentStatus != 'active') {
        customerUpdates['status'] = 'active';
      }

      if (customerUpdates.isNotEmpty) {
        transaction.update(customerDocRef, customerUpdates);
      }
    }

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final itemDocRef = itemDocRefs[i];
      final itemData = itemSnapshots[i].data() as Map<String, dynamic>? ?? {};
      final quantityInStock = (itemData['quantityInStock'] as num?)?.toInt() ?? 0;
      final newQty = quantityInStock - item.quantity;

      final movementDocRef = itemDocRef.collection('movements').doc();
      transaction.set(movementDocRef, {
        'itemId': item.inventoryItemId,
        'type': StockMovementType.stockOut.name,
        'quantity': item.quantity,
        'reason': 'Used in Installation for ${installation.customerName} (ID: ${installation.id})',
        'date': FieldValue.serverTimestamp(),
        'performedBy': installation.assignedEmployeeName ?? 'System',
      });

      transaction.update(itemDocRef, {
        'quantityInStock': newQty,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<void> addInstallation(InstallationModel installation) async {
    final docRef = _col.doc(installation.id.isEmpty ? null : installation.id);

    // Check if status is completed on creation
    if (installation.status == InstallationStatus.completed) {
      await _firestore.runTransaction((transaction) async {
        await _syncCustomerAndInventoryForCompletion(transaction, installation);

        // Save installation
        final data = installation.toMap();
        data['createdAt'] = FieldValue.serverTimestamp();
        data['completedAt'] = FieldValue.serverTimestamp();
        transaction.set(docRef, data);
      });
    } else {
      final data = installation.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      await docRef.set(data);
    }
  }

  @override
  Future<List<InstallationModel>> getInstallations({
    String? status,
    String? connectionType,
    String? employeeId,
    String? searchQuery,
  }) async {
    Query query = _col;

    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    if (connectionType != null && connectionType.isNotEmpty) {
      query = query.where('connectionType', isEqualTo: connectionType);
    }
    if (employeeId != null && employeeId.isNotEmpty) {
      query = query.where('assignedEmployeeId', isEqualTo: employeeId);
    }

    final snapshot = await query.get();
    List<InstallationModel> list = snapshot.docs.map((doc) => InstallationModel.fromFirestore(doc)).toList();

    // Sort in-memory by createdAt descending
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Filter in-memory by customer name if searchQuery is provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final queryLower = searchQuery.toLowerCase();
      list = list.where((inst) => inst.customerName.toLowerCase().contains(queryLower)).toList();
    }

    return list;
  }

  @override
  Future<List<InstallationModel>> getInstallationsByCustomer(String customerId) async {
    final snapshot = await _col
        .where('customerId', isEqualTo: customerId)
        .get();
    
    final list = snapshot.docs.map((doc) => InstallationModel.fromFirestore(doc)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> updateInstallation(InstallationModel installation) async {
    final docRef = _col.doc(installation.id);
    final currentDoc = await docRef.get();
    if (!currentDoc.exists) {
      throw Exception('Installation with ID ${installation.id} does not exist.');
    }

    final currentData = currentDoc.data() as Map<String, dynamic>? ?? {};
    final currentStatusStr = currentData['status'] as String? ?? 'pending';

    final isTransitioningToCompleted = currentStatusStr != 'completed' &&
        installation.status == InstallationStatus.completed;

    if (isTransitioningToCompleted) {
      await _firestore.runTransaction((transaction) async {
        await _syncCustomerAndInventoryForCompletion(transaction, installation);

        // Update installation doc
        final data = installation.toMap();
        data.remove('createdAt'); // keep original createdAt
        data['completedAt'] = FieldValue.serverTimestamp();
        transaction.update(docRef, data);
      });
    } else {
      final data = installation.toMap();
      data.remove('createdAt'); // keep original createdAt
      // Keep completedAt if already completed, else set if status completed
      if (installation.status == InstallationStatus.completed) {
        data['completedAt'] = currentData['completedAt'] ?? FieldValue.serverTimestamp();
      } else {
        data['completedAt'] = null;
      }
      await docRef.update(data);
    }
  }

  @override
  Future<void> deleteInstallation(String id) async {
    await _col.doc(id).delete();
  }
}
