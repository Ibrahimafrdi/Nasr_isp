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
    final data = item.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(item.id).set(data);
  }

  @override
  Future<List<InventoryItemModel>> getInventoryItems() async {
    final snapshot = await _col.orderBy('name').get();
    return snapshot.docs.map((doc) => InventoryItemModel.fromFirestore(doc)).toList();
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
