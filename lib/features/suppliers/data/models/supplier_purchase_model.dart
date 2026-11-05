import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_purchase_entity.dart';

class SupplierPurchaseModel extends SupplierPurchaseEntity {
  const SupplierPurchaseModel({
    required super.id,
    required super.supplierId,
    required super.itemId,
    required super.itemName,
    required super.quantity,
    required super.unitCost,
    required super.totalAmount,
    super.paidAmount = 0.0,
    required super.status,
    super.invoiceNo,
    super.notes,
    super.date,
    super.isCancelled = false,
    super.createdAt,
  });

  factory SupplierPurchaseModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return SupplierPurchaseModel(
      id: id ?? map['id'] as String? ?? '',
      supplierId: map['supplierId'] as String? ?? '',
      itemId: map['itemId'] as String? ?? '',
      itemName: map['itemName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      status: SupplierPaymentStatus.fromString(map['status'] as String?),
      invoiceNo: map['invoiceNo'] as String?,
      notes: map['notes'] as String?,
      date: _parseDate(map['date']),
      isCancelled: map['isCancelled'] as bool? ?? false,
      createdAt: _parseDate(map['createdAt']),
    );
  }

  factory SupplierPurchaseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SupplierPurchaseModel.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'unitCost': unitCost,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'status': status.name,
      'invoiceNo': invoiceNo,
      'notes': notes,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'isCancelled': isCancelled,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  Map<String, dynamic> toFirestore() {
    final map = toMap();
    map.remove('id');
    return map;
  }

  SupplierPurchaseEntity toEntity() => this;

  SupplierPurchaseModel copyWith({
    String? id,
    String? supplierId,
    String? itemId,
    String? itemName,
    int? quantity,
    double? unitCost,
    double? totalAmount,
    double? paidAmount,
    SupplierPaymentStatus? status,
    String? invoiceNo,
    String? notes,
    DateTime? date,
    bool? isCancelled,
    DateTime? createdAt,
  }) {
    return SupplierPurchaseModel(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      isCancelled: isCancelled ?? this.isCancelled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

