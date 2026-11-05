import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/inventory/data/models/inventory_item_model.dart';
import 'package:nasr_isp/features/suppliers/data/models/supplier_model.dart';
import 'package:nasr_isp/features/suppliers/data/models/supplier_payment_model.dart';
import 'package:nasr_isp/features/suppliers/data/models/supplier_purchase_model.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_detail_entity.dart';

abstract class SupplierRemoteDataSource {
  Future<String> addSupplier(SupplierModel supplier);
  Future<void> updateSupplier(SupplierModel supplier);
  Future<void> deactivateSupplier(String supplierId);
  Future<List<SupplierModel>> getSuppliers({bool? activeOnly});
  Future<SupplierDetailEntity> getSupplierDetail(String supplierId);
  Future<void> addSupplierPayment({
    required String supplierId,
    required String purchaseId,
    required double amount,
    required PaymentMethod method,
    DateTime? date,
    String? notes,
  });
  Future<void> cancelPurchase(String purchaseId, {String? performedBy});
  Future<void> recordStockPurchase({
    required String supplierId,
    required String itemId,
    required String itemName,
    required int quantity,
    required double unitCost,
    double paidNow = 0.0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    DateTime? date,
    String? invoiceNo,
    String? notes,
    String? performedBy,
    InventoryItemModel? inventoryItem,
    bool isNewItem = false,
  });
}

class SupplierRemoteDataSourceImpl implements SupplierRemoteDataSource {
  final FirebaseFirestore _firestore;

  SupplierRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _suppliersCol => _firestore.collection('suppliers');
  CollectionReference get _purchasesCol => _firestore.collection('supplier_purchases');
  CollectionReference get _paymentsCol => _firestore.collection('supplier_payments');
  CollectionReference get _inventoryCol => _firestore.collection('inventory');

  @override
  Future<String> addSupplier(SupplierModel supplier) async {
    final docRef = _suppliersCol.doc(supplier.id.isNotEmpty ? supplier.id : null);
    final data = supplier.toMap();
    data['id'] = docRef.id;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
    return docRef.id;
  }

  @override
  Future<void> updateSupplier(SupplierModel supplier) async {
    final data = {
      'name': supplier.name.trim(),
      'phone': supplier.phone.trim(),
      'address': supplier.address?.trim() ?? '',
      'notes': supplier.notes?.trim() ?? '',
      'isActive': supplier.isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _suppliersCol.doc(supplier.id).update(data);
  }

  @override
  Future<void> deactivateSupplier(String supplierId) async {
    await _suppliersCol.doc(supplierId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<SupplierModel>> getSuppliers({bool? activeOnly}) async {
    Query query = _suppliersCol;
    if (activeOnly == true) {
      query = query.where('isActive', isEqualTo: true);
    }
    final snapshot = await query.get();
    final list = snapshot.docs
        .map((doc) => SupplierModel.fromFirestore(doc))
        .toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Future<SupplierDetailEntity> getSupplierDetail(String supplierId) async {
    final doc = await _suppliersCol.doc(supplierId).get();
    if (!doc.exists) {
      throw Exception('Supplier not found.');
    }
    final supplier = SupplierModel.fromFirestore(doc);

    final purchasesSnap = await _purchasesCol
        .where('supplierId', isEqualTo: supplierId)
        .get();
    final purchases = purchasesSnap.docs
        .map((d) => SupplierPurchaseModel.fromFirestore(d))
        .toList();
    purchases.sort((a, b) {
      final aDate = a.date ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.date ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    final paymentsSnap = await _paymentsCol
        .where('supplierId', isEqualTo: supplierId)
        .get();
    final payments = paymentsSnap.docs
        .map((d) => SupplierPaymentModel.fromFirestore(d))
        .toList();
    payments.sort((a, b) {
      final aDate = a.date ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.date ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return SupplierDetailEntity(
      supplier: supplier,
      purchases: purchases,
      payments: payments,
    );
  }

  @override
  Future<void> addSupplierPayment({
    required String supplierId,
    required String purchaseId,
    required double amount,
    required PaymentMethod method,
    DateTime? date,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw Exception('Payment amount must be greater than zero.');
    }

    final purchaseDocRef = _purchasesCol.doc(purchaseId);
    final supplierDocRef = _suppliersCol.doc(supplierId);
    final paymentDocRef = _paymentsCol.doc();

    await _firestore.runTransaction((transaction) async {
      // 1. Reads
      final purchaseSnap = await transaction.get(purchaseDocRef);
      if (!purchaseSnap.exists) {
        throw Exception('Purchase not found.');
      }
      final purchaseData = purchaseSnap.data() as Map<String, dynamic>? ?? {};
      if (purchaseData['isCancelled'] == true) {
        throw Exception('Cannot record payment for a cancelled purchase.');
      }

      final totalAmount = (purchaseData['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final paidAmount = (purchaseData['paidAmount'] as num?)?.toDouble() ?? 0.0;
      final remaining = totalAmount - paidAmount;

      if (amount > remaining + 0.0001) {
        throw Exception(
          'Payment amount (Rs. ${amount.toStringAsFixed(0)}) exceeds remaining balance (Rs. ${remaining.toStringAsFixed(0)}).',
        );
      }

      final supplierSnap = await transaction.get(supplierDocRef);
      if (!supplierSnap.exists) {
        throw Exception('Supplier not found.');
      }
      final supplierData = supplierSnap.data() as Map<String, dynamic>? ?? {};

      // 2. Calculations
      final newPurchasePaid = paidAmount + amount;
      final SupplierPaymentStatus newStatus =
          (newPurchasePaid >= totalAmount - 0.0001)
              ? SupplierPaymentStatus.paid
              : SupplierPaymentStatus.partial;

      final currentTotalPurchased = (supplierData['totalPurchased'] as num?)?.toDouble() ?? 0.0;
      final currentTotalPaid = (supplierData['totalPaid'] as num?)?.toDouble() ?? 0.0;
      final newSupplierPaid = currentTotalPaid + amount;
      final newPendingBalance = currentTotalPurchased - newSupplierPaid;

      // 3. Writes
      transaction.set(paymentDocRef, {
        'id': paymentDocRef.id,
        'supplierId': supplierId,
        'purchaseId': purchaseId,
        'amount': amount,
        'date': date != null ? Timestamp.fromDate(date) : FieldValue.serverTimestamp(),
        'method': method.name,
        'notes': notes ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(purchaseDocRef, {
        'paidAmount': newPurchasePaid,
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(supplierDocRef, {
        'totalPaid': newSupplierPaid,
        'pendingBalance': newPendingBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> cancelPurchase(String purchaseId, {String? performedBy}) async {
    // Check if payments exist
    final paymentsSnap = await _paymentsCol
        .where('purchaseId', isEqualTo: purchaseId)
        .limit(1)
        .get();
    if (paymentsSnap.docs.isNotEmpty) {
      throw Exception('Cannot cancel purchase with recorded payments. Please reverse payments first.');
    }

    final purchaseDocRef = _purchasesCol.doc(purchaseId);

    await _firestore.runTransaction((transaction) async {
      // 1. Reads
      final purchaseSnap = await transaction.get(purchaseDocRef);
      if (!purchaseSnap.exists) {
        throw Exception('Purchase not found.');
      }
      final purchaseData = purchaseSnap.data() as Map<String, dynamic>? ?? {};
      if (purchaseData['isCancelled'] == true) {
        throw Exception('Purchase is already cancelled.');
      }

      final paidAmount = (purchaseData['paidAmount'] as num?)?.toDouble() ?? 0.0;
      if (paidAmount > 0) {
        throw Exception('Cannot cancel purchase with paid amount greater than 0.');
      }

      final supplierId = purchaseData['supplierId'] as String? ?? '';
      final itemId = purchaseData['itemId'] as String? ?? '';
      final qty = (purchaseData['quantity'] as num?)?.toInt() ?? 0;
      final totalAmount = (purchaseData['totalAmount'] as num?)?.toDouble() ?? 0.0;

      final supplierDocRef = _suppliersCol.doc(supplierId);
      final supplierSnap = await transaction.get(supplierDocRef);

      final itemDocRef = _inventoryCol.doc(itemId);
      final itemSnap = await transaction.get(itemDocRef);

      // 2. Calculations & assertions
      if (itemSnap.exists) {
        final itemData = itemSnap.data() as Map<String, dynamic>? ?? {};
        final currentStock = (itemData['quantityInStock'] as num?)?.toInt() ?? 0;
        if (currentStock - qty < 0) {
          throw Exception(
            'Cannot cancel purchase: reversing $qty units would result in negative stock ($currentStock available).',
          );
        }

        final movementDocRef = itemDocRef.collection('movements').doc();
        transaction.update(itemDocRef, {
          'quantityInStock': currentStock - qty,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(movementDocRef, {
          'id': movementDocRef.id,
          'itemId': itemId,
          'type': StockMovementType.stockOut.name,
          'quantity': qty,
          'reason': 'Cancelled supplier purchase #$purchaseId',
          'date': FieldValue.serverTimestamp(),
          'performedBy': performedBy ?? 'System',
        });
      }

      if (supplierSnap.exists) {
        final supplierData = supplierSnap.data() as Map<String, dynamic>? ?? {};
        final currentTotalPurchased = (supplierData['totalPurchased'] as num?)?.toDouble() ?? 0.0;
        final currentTotalPaid = (supplierData['totalPaid'] as num?)?.toDouble() ?? 0.0;
        final newTotalPurchased = currentTotalPurchased - totalAmount;
        final newPendingBalance = (newTotalPurchased < 0 ? 0.0 : newTotalPurchased) - currentTotalPaid;

        transaction.update(supplierDocRef, {
          'totalPurchased': newTotalPurchased < 0 ? 0.0 : newTotalPurchased,
          'pendingBalance': newPendingBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(purchaseDocRef, {
        'isCancelled': true,
        'status': SupplierPaymentStatus.unpaid.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> recordStockPurchase({
    required String supplierId,
    required String itemId,
    required String itemName,
    required int quantity,
    required double unitCost,
    double paidNow = 0.0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    DateTime? date,
    String? invoiceNo,
    String? notes,
    String? performedBy,
    InventoryItemModel? inventoryItem,
    bool isNewItem = false,
  }) async {
    final double totalAmount = quantity * unitCost;
    if (paidNow < 0 || paidNow > totalAmount + 0.0001) {
      throw Exception('Paid now (Rs. $paidNow) must be between 0 and total amount (Rs. $totalAmount).');
    }

    final itemDocRef = _inventoryCol.doc(itemId);
    final supplierDocRef = _suppliersCol.doc(supplierId);
    final purchaseDocRef = _purchasesCol.doc();
    final paymentDocRef = _paymentsCol.doc();
    final movementDocRef = itemDocRef.collection('movements').doc();

    await _firestore.runTransaction((transaction) async {
      // 1. Reads
      final supplierSnap = await transaction.get(supplierDocRef);
      if (!supplierSnap.exists) {
        throw Exception('Supplier with ID "$supplierId" does not exist.');
      }
      final supplierData = supplierSnap.data() as Map<String, dynamic>? ?? {};
      if (supplierData['isActive'] == false) {
        throw Exception('Cannot add purchase for an inactive supplier.');
      }

      final itemSnap = await transaction.get(itemDocRef);
      final bool itemExists = itemSnap.exists;

      // 2. Calculations
      int oldQty = 0;
      double oldCost = 0.0;
      if (itemExists) {
        final existingItemData = itemSnap.data() as Map<String, dynamic>? ?? {};
        oldQty = (existingItemData['quantityInStock'] as num?)?.toInt() ?? 0;
        oldCost = (existingItemData['unitCost'] as num?)?.toDouble() ?? 0.0;
      }

      final int newQty = oldQty + quantity;
      // Weighted average: (oldQty*oldCost + newQty*newCost) / (oldQty+newQty). If oldQty <= 0, use the new cost
      final double weightedCost = (oldQty <= 0)
          ? unitCost
          : ((oldQty * oldCost + quantity * unitCost) / (oldQty + quantity));

      final SupplierPaymentStatus purchaseStatus;
      if (paidNow >= totalAmount - 0.0001) {
        purchaseStatus = SupplierPaymentStatus.paid;
      } else if (paidNow > 0) {
        purchaseStatus = SupplierPaymentStatus.partial;
      } else {
        purchaseStatus = SupplierPaymentStatus.unpaid;
      }

      final double currentTotalPurchased = (supplierData['totalPurchased'] as num?)?.toDouble() ?? 0.0;
      final double currentTotalPaid = (supplierData['totalPaid'] as num?)?.toDouble() ?? 0.0;
      final double newTotalPurchased = currentTotalPurchased + totalAmount;
      final double newTotalPaid = currentTotalPaid + paidNow;
      final double newPendingBalance = newTotalPurchased - newTotalPaid;

      final supplierName = (supplierData['name'] as String? ?? '').trim();

      // 3. Writes
      // (a) Inventory item
      if (itemExists) {
        transaction.update(itemDocRef, {
          'quantityInStock': newQty,
          'unitCost': weightedCost,
          'supplier': supplierName.isNotEmpty ? supplierName : supplierId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final newItemData = inventoryItem != null ? inventoryItem.toFirestore() : <String, dynamic>{};
        newItemData['name'] = itemName;
        newItemData['quantityInStock'] = newQty;
        newItemData['unitCost'] = weightedCost;
        newItemData['supplier'] = supplierName.isNotEmpty ? supplierName : supplierId;
        newItemData['createdAt'] = FieldValue.serverTimestamp();
        newItemData['updatedAt'] = FieldValue.serverTimestamp();
        transaction.set(itemDocRef, newItemData);
      }

      // (b) Stock Movement
      final movementReason = (notes != null && notes.isNotEmpty)
          ? notes
          : ((invoiceNo != null && invoiceNo.isNotEmpty)
              ? 'Purchased via Invoice #$invoiceNo'
              : 'Restocked from $supplierName');
      transaction.set(movementDocRef, {
        'id': movementDocRef.id,
        'itemId': itemId,
        'type': StockMovementType.stockIn.name,
        'quantity': quantity,
        'reason': movementReason,
        'date': date != null ? Timestamp.fromDate(date) : FieldValue.serverTimestamp(),
        'performedBy': performedBy ?? 'Admin',
      });

      // (c) Supplier purchase
      transaction.set(purchaseDocRef, {
        'id': purchaseDocRef.id,
        'supplierId': supplierId,
        'itemId': itemId,
        'itemName': itemName,
        'quantity': quantity,
        'unitCost': unitCost,
        'totalAmount': totalAmount,
        'paidAmount': paidNow,
        'status': purchaseStatus.name,
        'invoiceNo': invoiceNo ?? '',
        'notes': notes ?? '',
        'date': date != null ? Timestamp.fromDate(date) : FieldValue.serverTimestamp(),
        'isCancelled': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // (d) Supplier payment if paidNow > 0
      if (paidNow > 0) {
        transaction.set(paymentDocRef, {
          'id': paymentDocRef.id,
          'supplierId': supplierId,
          'purchaseId': purchaseDocRef.id,
          'amount': paidNow,
          'date': date != null ? Timestamp.fromDate(date) : FieldValue.serverTimestamp(),
          'method': paymentMethod.name,
          'notes': notes ?? 'Initial payment on purchase',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // (e) Update supplier totals
      transaction.update(supplierDocRef, {
        'totalPurchased': newTotalPurchased,
        'totalPaid': newTotalPaid,
        'pendingBalance': newPendingBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

