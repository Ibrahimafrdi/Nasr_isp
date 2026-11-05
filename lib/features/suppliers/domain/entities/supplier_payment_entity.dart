import 'package:equatable/equatable.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';

class SupplierPaymentEntity extends Equatable {
  final String id;
  final String supplierId;
  final String purchaseId;
  final double amount;
  final DateTime? date;
  final PaymentMethod method;
  final String? notes;
  final DateTime? createdAt;

  const SupplierPaymentEntity({
    required this.id,
    required this.supplierId,
    required this.purchaseId,
    required this.amount,
    this.date,
    required this.method,
    this.notes,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        supplierId,
        purchaseId,
        amount,
        date,
        method,
        notes,
        createdAt,
      ];
}

