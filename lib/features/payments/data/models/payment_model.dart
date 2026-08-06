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
    super.paymentDate,
    super.type,
    super.packageCostAtBilling,
    super.periodEnd,
  });

  /// Rebuilds a model from any entity, preserving every field. Use this rather
  /// than a hand-written constructor call at mapping boundaries — the previous
  /// open-coded copies silently dropped whichever field was added last.
  factory PaymentModel.from(PaymentEntity e) => e is PaymentModel
      ? e
      : PaymentModel(
          id: e.id,
          customerId: e.customerId,
          customerName: e.customerName,
          amount: e.amount,
          paidAmount: e.paidAmount,
          status: e.status,
          dueDate: e.dueDate,
          completedDate: e.completedDate,
          method: e.method,
          notes: e.notes,
          billingMonth: e.billingMonth,
          createdAt: e.createdAt,
          paymentDate: e.paymentDate,
          type: e.type,
          packageCostAtBilling: e.packageCostAtBilling,
          periodEnd: e.periodEnd,
        );

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? '',
      dueDate: _parseDate(map['dueDate']),
      completedDate: _parseDate(map['completedDate']),
      method: (map['method'] ?? map['paymentMethod']) as String?,
      notes: map['notes'] as String?,
      billingMonth: map['billingMonth'] as String?,
      createdAt: _parseDate(map['createdAt']),
      paymentDate: _parseDate(map['paymentDate']),
      type: PaymentType.fromName(map['type'] as String?),
      // Left null when absent so callers can tell "cost never snapshotted"
      // apart from "cost is genuinely zero".
      packageCostAtBilling: (map['packageCostAtBilling'] as num?)?.toDouble(),
      periodEnd: _parseDate(map['periodEnd']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'paidAmount': paidAmount,
      'status': status,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'completedDate': completedDate != null
          ? Timestamp.fromDate(completedDate!)
          : null,
      'method': method,
      'paymentMethod': method,
      'notes': notes,
      'billingMonth': billingMonth,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
      'type': type.name,
      'packageCostAtBilling': packageCostAtBilling,
      'periodEnd': periodEnd != null ? Timestamp.fromDate(periodEnd!) : null,
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
    PaymentType? type,
    double? packageCostAtBilling,
    DateTime? periodEnd,
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
      paymentDate: paymentDate ?? this.paymentDate,
      type: type ?? this.type,
      packageCostAtBilling: packageCostAtBilling ?? this.packageCostAtBilling,
      periodEnd: periodEnd ?? this.periodEnd,
    );
  }
}
