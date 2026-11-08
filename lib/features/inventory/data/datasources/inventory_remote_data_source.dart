import 'package:nasr_isp/features/suppliers/data/datasources/supplier_remote_data_source.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/inventory/data/models/inventory_item_model.dart';
import 'package:nasr_isp/features/inventory/data/models/stock_movement_model.dart';
import 'package:nasr_isp/features/inventory/data/models/stock_issue_model.dart';

abstract class InventoryRemoteDataSource {
  Future<void> addInventoryItem(
    InventoryItemModel item, {
    String? supplierId,
    double? unitCost,
    double paidNow = 0.0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    DateTime? purchaseDate,
    String? invoiceNo,
    String? purchaseNotes,
    String? performedBy,
  });
  Future<List<InventoryItemModel>> getInventoryItems();
  Future<void> updateInventoryItem(InventoryItemModel item);
  Future<void> deleteInventoryItem(String itemId);
  Future<void> addStockMovement(
    String itemId,
    StockMovementModel movement, {
    String? supplierId,
    double? unitCost,
    double paidNow = 0.0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    DateTime? purchaseDate,
    String? invoiceNo,
    String? purchaseNotes,
  });
  Future<List<StockMovementModel>> getStockMovements(String itemId);
  Future<void> issueStock(StockIssueModel issue);
  Future<List<StockIssueModel>> getStockIssues();
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SupplierRemoteDataSource _supplierRemoteDataSource;

  InventoryRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    SupplierRemoteDataSource? supplierRemoteDataSource,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = firebaseAuth ?? FirebaseAuth.instance,
       _supplierRemoteDataSource =
           supplierRemoteDataSource ??
           SupplierRemoteDataSourceImpl(
             firestore: firestore ?? FirebaseFirestore.instance,
           );

  CollectionReference get _col => _firestore.collection('inventory');

  @override
  Future<void> addInventoryItem(
    InventoryItemModel item, {
    String? supplierId,
    double? unitCost,
    double paidNow = 0.0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    DateTime? purchaseDate,
    String? invoiceNo,
    String? purchaseNotes,
    String? performedBy,
  }) async {
    final querySnapshot = await _col.get();
    DocumentSnapshot? existingDoc;

    final targetName = item.name.trim().toLowerCase();
    for (final doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final name = (data['name'] as String? ?? '').trim().toLowerCase();
      if (name == targetName) {
        existingDoc = doc;
        break;
      }
    }

    final user = _auth.currentUser;
    final effectiveActor = (performedBy != null && performedBy.isNotEmpty)
        ? performedBy
        : (user?.displayName != null && user!.displayName!.isNotEmpty
              ? user.displayName!
              : (user?.email ?? user?.uid ?? 'Admin'));
    final effectiveCost = unitCost ?? item.unitCost;

    if (supplierId != null && supplierId.isNotEmpty) {
      final targetId =
          existingDoc?.id ?? (item.id.isNotEmpty ? item.id : _col.doc().id);
      await _supplierRemoteDataSource.recordStockPurchase(
        supplierId: supplierId,
        itemId: targetId,
        itemName: item.name,
        quantity: item.quantityInStock,
        unitCost: effectiveCost,
        paidNow: paidNow,
        paymentMethod: paymentMethod,
        date: purchaseDate,
        invoiceNo: invoiceNo,
        notes: purchaseNotes,
        performedBy: effectiveActor,
        inventoryItem: item.copyWith(id: targetId),
        isNewItem: existingDoc == null,
      );
      return;
    }

    if (existingDoc != null) {
      final existingData = existingDoc.data() as Map<String, dynamic>? ?? {};
      final currentQty =
          (existingData['quantityInStock'] as num?)?.toInt() ?? 0;
      final newQty = currentQty + item.quantityInStock;

      final updatedData = item.toFirestore();
      updatedData['id'] = existingDoc.id;
      updatedData['quantityInStock'] = newQty;
      updatedData.remove('createdAt');
      updatedData['updatedAt'] = FieldValue.serverTimestamp();

      await _col.doc(existingDoc.id).update(updatedData);

      final movementDocRef = _col
          .doc(existingDoc.id)
          .collection('movements')
          .doc();
      await movementDocRef.set({
        'id': movementDocRef.id,
        'itemId': existingDoc.id,
        'type': StockMovementType.stockIn.name,
        'quantity': item.quantityInStock,
        'reason': 'Restocked via Add Item',
        'date': FieldValue.serverTimestamp(),
        'performedBy': effectiveActor,
      });
    } else {
      final data = item.toFirestore();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _col.doc(item.id.isNotEmpty ? item.id : null).set(data);
    }
  }

  @override
  Future<List<InventoryItemModel>> getInventoryItems() async {
    final snapshot = await _col.orderBy('name').get();
    return snapshot.docs
        .map((doc) => InventoryItemModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<void> updateInventoryItem(InventoryItemModel item) async {
    final data = item.toFirestore();
    data.remove('createdAt');
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(item.id).update(data);
  }

  @override
  Future<void> deleteInventoryItem(String itemId) async {
    // Implement recursive cleanup for movements subcollection + parent item deletion
    final itemDocRef = _col.doc(itemId);
    final movementsColRef = itemDocRef.collection('movements');

    final movementsSnapshot = await movementsColRef.get();
    final batch = _firestore.batch();

    for (final doc in movementsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(itemDocRef);

    await batch.commit();
  }

  @override
  Future<void> addStockMovement(
    String itemId,
    StockMovementModel movement, {
    String? supplierId,
    double? unitCost,
    double paidNow = 0.0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    DateTime? purchaseDate,
    String? invoiceNo,
    String? purchaseNotes,
  }) async {
    if (movement.type == StockMovementType.stockIn &&
        supplierId != null &&
        supplierId.isNotEmpty) {
      final itemDoc = await _col.doc(itemId).get();
      if (!itemDoc.exists) {
        throw Exception('Inventory item with ID $itemId does not exist.');
      }
      final itemData = itemDoc.data() as Map<String, dynamic>? ?? {};
      final itemName = itemData['name'] as String? ?? 'Item';
      final effectiveCost =
          unitCost ?? (itemData['unitCost'] as num?)?.toDouble() ?? 0.0;

      await _supplierRemoteDataSource.recordStockPurchase(
        supplierId: supplierId,
        itemId: itemId,
        itemName: itemName,
        quantity: movement.quantity,
        unitCost: effectiveCost,
        paidNow: paidNow,
        paymentMethod: paymentMethod,
        date: purchaseDate ?? movement.date,
        invoiceNo: invoiceNo,
        notes: purchaseNotes ?? movement.reason,
        performedBy: movement.performedBy,
        isNewItem: false,
      );
      return;
    }

    final itemDocRef = _col.doc(itemId);
    final movementDocRef = itemDocRef.collection('movements').doc(movement.id);

    await _firestore.runTransaction((transaction) async {
      final itemDoc = await transaction.get(itemDocRef);
      if (!itemDoc.exists) {
        throw Exception('Inventory item with ID $itemId does not exist.');
      }

      final itemData = itemDoc.data() as Map<String, dynamic>? ?? {};
      final currentQty = (itemData['quantityInStock'] as num?)?.toInt() ?? 0;

      int updatedQty;
      if (movement.type == StockMovementType.stockIn) {
        updatedQty = currentQty + movement.quantity;
      } else {
        updatedQty = currentQty - movement.quantity;
        if (updatedQty < 0) {
          final itemName = itemData['name'] as String? ?? 'this item';
          throw Exception(
            'Insufficient stock for $itemName. Available: $currentQty, Requested: ${movement.quantity}',
          );
        }
      }

      transaction.set(movementDocRef, {
        ...movement.toFirestore(),
        'date': FieldValue.serverTimestamp(),
      });

      transaction.update(itemDocRef, {
        'quantityInStock': updatedQty,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<List<StockMovementModel>> getStockMovements(String itemId) async {
    final movementsSnapshot = await _col
        .doc(itemId)
        .collection('movements')
        .orderBy('date', descending: true)
        .get();

    return movementsSnapshot.docs
        .map((doc) => StockMovementModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<void> issueStock(StockIssueModel issue) async {
    final itemRef = _col.doc(issue.itemId);
    // Validate BEFORE the transaction: on web, an error thrown inside a
    // transaction is boxed and its real message is lost.
    issue.validate();
    final issueRef = _firestore.collection('stock_issues').doc(issue.id);
    final movementRef = itemRef.collection('movements').doc();
    await _firestore.runTransaction((transaction) async {
      final itemSnapshot = await transaction.get(itemRef);
      if (!itemSnapshot.exists) {
        throw StateError('Inventory item "${issue.itemId}" no longer exists.');
      }

      final data = itemSnapshot.data() as Map<String, dynamic>? ?? {};
      final currentStock = (data['quantityInStock'] as num?)?.toInt() ?? 0;
      if (issue.quantity > currentStock) {
        final itemName = data['name'] as String? ?? 'item';
        throw StateError(
          'Cannot issue ${issue.quantity} units of $itemName; only $currentStock are currently in stock.',
        );
      }

      final issueSnapshot = issue.copyWith(
        itemName: data['name'] as String? ?? issue.itemName,
        unitCost: (data['unitCost'] as num?)?.toDouble() ?? 0,
      );
      transaction.update(itemRef, {
        'quantityInStock': currentStock - issue.quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(issueRef, {
        ...issueSnapshot.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      final buyer = issue.buyerName?.trim() ?? '';
      transaction.set(movementRef, {
        'id': movementRef.id,
        'itemId': issue.itemId,
        'type': StockMovementType.stockOut.name,
        'quantity': issue.quantity,
        'reason': issue.purpose == StockIssuePurpose.sale
            ? 'Sold to ${buyer.isEmpty ? 'customer' : buyer}'
            : 'Issued: ${issue.purpose.label}',
        'date': FieldValue.serverTimestamp(),
        'performedBy': issue.issuedBy,
      });
    });
  }

  @override
  Future<List<StockIssueModel>> getStockIssues() async {
    final snapshot = await _firestore.collection('stock_issues').get();
    return snapshot.docs.map(StockIssueModel.fromFirestore).toList();
  }
}
