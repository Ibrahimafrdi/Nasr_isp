import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final double paidAmount;
  final String status;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final String? method;
  final String? notes;
  final String? billingMonth;
  final DateTime? createdAt;
  final DateTime? paymentDate;

  const PaymentEntity({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.paidAmount,
    required this.status,
    this.dueDate,
    this.completedDate,
    this.method,
    this.notes,
    this.billingMonth,
    this.createdAt,
    this.paymentDate,
  });

  double get remainingAmount => (amount - paidAmount).clamp(0, double.infinity);

  @override
  List<Object?> get props => [
    id,
    customerId,
    customerName,
    amount,
    paidAmount,
    status,
    dueDate,
    completedDate,
    method,
    notes,
    billingMonth,
    createdAt,
    paymentDate,
  ];

  PaymentEntity copyWith({
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
  }) => PaymentEntity(
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
  );
}
