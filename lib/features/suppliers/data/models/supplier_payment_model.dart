import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_payment_entity.dart';

class SupplierPaymentModel extends SupplierPaymentEntity {
  const SupplierPaymentModel({
    required super.id,
    required super.supplierId,
    required super.purchaseId,
    required super.amount,
    super.date,
    required super.method,
    super.notes,
    super.createdAt,
  });

  factory SupplierPaymentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return SupplierPaymentModel(
      id: id ?? map['id'] as String? ?? '',
      supplierId: map['supplierId'] as String? ?? '',
      purchaseId: map['purchaseId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: _parseDate(map['date']),
      method: PaymentMethod.fromString(map['method'] as String?),
      notes: map['notes'] as String?,
      createdAt: _parseDate(map['createdAt']),
    );
  }

  factory SupplierPaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SupplierPaymentModel.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'purchaseId': purchaseId,
      'amount': amount,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'method': method.name,
      'notes': notes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  Map<String, dynamic> toFirestore() {
    final map = toMap();
    map.remove('id');
    return map;
  }

  SupplierPaymentEntity toEntity() => this;

  SupplierPaymentModel copyWith({
    String? id,
    String? supplierId,
    String? purchaseId,
    double? amount,
    DateTime? date,
    PaymentMethod? method,
    String? notes,
    DateTime? createdAt,
  }) {
    return SupplierPaymentModel(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      purchaseId: purchaseId ?? this.purchaseId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      method: method ?? this.method,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

