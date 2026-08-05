import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/inventory/data/models/inventory_item_model.dart';
import 'package:nasr_isp/features/inventory/data/models/stock_movement_model.dart';

abstract class InventoryRemoteDataSource {
  Future<void> addInventoryItem(InventoryItemModel item);
  Future<List<InventoryItemModel>> getInventoryItems();
  Future<void> updateInventoryItem(InventoryItemModel item);
  Future<void> deleteInventoryItem(String itemId);
  Future<void> addStockMovement(String itemId, StockMovementModel movement);
  Future<List<StockMovementModel>> getStockMovements(String itemId);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final FirebaseFirestore _firestore;

  InventoryRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('inventory');

  @override
  Future<void> addInventoryItem(InventoryItemModel item) async {
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

    if (existingDoc != null) {
      // Item with matching name exists! Update stock of existing item instead of creating duplicate entry.
      final existingData = existingDoc.data() as Map<String, dynamic>? ?? {};
      final currentQty = (existingData['quantityInStock'] as num?)?.toInt() ?? 0;
      final newQty = currentQty + item.quantityInStock;

      final updatedData = item.toFirestore();
      updatedData['id'] = existingDoc.id;
      updatedData['quantityInStock'] = newQty;
      updatedData.remove('createdAt');
      updatedData['updatedAt'] = FieldValue.serverTimestamp();

      await _col.doc(existingDoc.id).update(updatedData);

      // Record stock-in movement for the restock
      final movementDocRef = _col.doc(existingDoc.id).collection('movements').doc();
      await movementDocRef.set({
        'id': movementDocRef.id,
        'itemId': existingDoc.id,
        'type': StockMovementType.stockIn.name,
        'quantity': item.quantityInStock,
        'reason': 'Restocked via Add Item',
        'date': FieldValue.serverTimestamp(),
        'performedBy': 'Admin',
      });
    } else {
      final data = item.toFirestore();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _col.doc(item.id).set(data);
    }
  }

  @override
  Future<List<InventoryItemModel>> getInventoryItems() async {
    final snapshot = await _col.orderBy('name').get();
    final Map<String, InventoryItemModel> itemsMap = {};

    for (final doc in snapshot.docs) {
      final item = InventoryItemModel.fromFirestore(doc);
      final key = item.name.trim().toLowerCase();
      if (itemsMap.containsKey(key)) {
        // Consolidate duplicate records if any exist in database
        final existing = itemsMap[key]!;
        final mergedQty = existing.quantityInStock + item.quantityInStock;
        final mergedModel = existing.copyWith(
          quantityInStock: mergedQty,
          unitCost: item.unitCost > 0 ? item.unitCost : existing.unitCost,
          sellPrice: item.sellPrice > 0 ? item.sellPrice : existing.sellPrice,
        );
        itemsMap[key] = mergedModel;

        // Clean up duplicate document in background
        _col.doc(existing.id).update({'quantityInStock': mergedQty});
        deleteInventoryItem(doc.id);
      } else {
        itemsMap[key] = item;
      }
    }

    return itemsMap.values.toList();
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
  Future<void> addStockMovement(String itemId, StockMovementModel movement) async {
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
              'Insufficient stock for $itemName. Available: $currentQty, Requested: ${movement.quantity}');
        }
      }

      // Add movement document
      transaction.set(movementDocRef, {
        ...movement.toFirestore(),
        'date': FieldValue.serverTimestamp(),
      });

      // Update parent document quantityInStock and updatedAt
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
}
