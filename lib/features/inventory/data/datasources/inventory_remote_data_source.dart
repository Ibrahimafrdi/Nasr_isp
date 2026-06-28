import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final double unitPrice;
  final String? description;
  final DateTime createdAt;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    this.description,
    required this.createdAt,
  });

  factory InventoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItem(
      id: doc.id,
      name: data['name'] as String,
      category: data['category'] as String,
      quantity: (data['quantity'] as num).toInt(),
      unitPrice: (data['unitPrice'] as num).toDouble(),
      description: data['description'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'description': description,
  };
}

abstract class InventoryRemoteDataSource {
  Future<void> addItem(InventoryItem item);
  Future<List<InventoryItem>> getItems();
  Future<void> updateItem(InventoryItem item);
  Future<void> deleteItem(String id);
  Future<void> adjustQuantity(String id, int newQuantity);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final FirebaseFirestore _firestore;

  InventoryRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('inventory');

  @override
  Future<void> addItem(InventoryItem item) async {
    final data = item.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _col.doc(item.id).set(data);
  }

  @override
  Future<List<InventoryItem>> getItems() async {
    final snapshot = await _col.orderBy('name').get();
    return snapshot.docs.map((doc) => InventoryItem.fromFirestore(doc)).toList();
  }

  @override
  Future<void> updateItem(InventoryItem item) async {
    final data = item.toMap();
    await _col.doc(item.id).update(data);
  }

  @override
  Future<void> deleteItem(String id) async {
    await _col.doc(id).delete();
  }

  @override
  Future<void> adjustQuantity(String id, int newQuantity) async {
    await _col.doc(id).update({'quantity': newQuantity});
  }
}
