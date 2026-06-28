import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.customerId,
    required super.customerName,
    required super.amount,
    required super.paidAmount,
    required super.status,
    super.dueDate,
    super.completedDate,
    super.method,
    super.notes,
    super.billingMonth,
    super.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? '',
      dueDate: map['dueDate'] is Timestamp
          ? (map['dueDate'] as Timestamp).toDate()
          : (map['dueDate'] != null
                ? DateTime.tryParse(map['dueDate'].toString())
                : null),
      completedDate: map['completedDate'] is Timestamp
          ? (map['completedDate'] as Timestamp).toDate()
          : (map['completedDate'] != null
                ? DateTime.tryParse(map['completedDate'].toString())
                : null),
      method: (map['method'] ?? map['paymentMethod']) as String?,
      notes: map['notes'] as String?,
      billingMonth: map['billingMonth'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] != null
                ? DateTime.tryParse(map['createdAt'].toString())
                : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'paidAmount': paidAmount,
      'status': status,
      'dueDate': dueDate,
      'completedDate': completedDate,
      'method': method,
      'paymentMethod': method, // write to both for compatibility
      'notes': notes,
      'billingMonth': billingMonth,
      'createdAt': createdAt,
    };
  }

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PaymentModel.fromMap({...data, 'id': doc.id});
  }

  @override
  PaymentModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    double? amount,
    double? paidAmount,
    String? status,
    DateTime? dueDate,
    DateTime? completedDate,
    String? method,
    String? notes,
    String? billingMonth,
    DateTime? createdAt,

    DateTime? paymentDate,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      completedDate: completedDate ?? this.completedDate,
      method: method ?? this.method,
      notes: notes ?? this.notes,
      billingMonth: billingMonth ?? this.billingMonth,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
