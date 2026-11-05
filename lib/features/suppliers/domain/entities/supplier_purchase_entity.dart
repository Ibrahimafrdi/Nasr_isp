import 'package:equatable/equatable.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';

class SupplierPurchaseEntity extends Equatable {
  final String id;
  final String supplierId;
  final String itemId;
  final String itemName;
  final int quantity;
  final double unitCost;
  final double totalAmount;
  final double paidAmount;
  final SupplierPaymentStatus status;
  final String? invoiceNo;
  final String? notes;
  final DateTime? date;
  final bool isCancelled;
  final DateTime? createdAt;

  const SupplierPurchaseEntity({
    required this.id,
    required this.supplierId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitCost,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.status,
    this.invoiceNo,
    this.notes,
    this.date,
    this.isCancelled = false,
    this.createdAt,
  });

  double get remainingAmount {
    final rem = totalAmount - paidAmount;
    return rem < 0 ? 0.0 : rem;
  }

  bool get canBeCancelled => !isCancelled && paidAmount <= 0.0001;

  @override
  List<Object?> get props => [
        id,
        supplierId,
        itemId,
        itemName,
        quantity,
        unitCost,
        totalAmount,
        paidAmount,
        status,
        invoiceNo,
        notes,
        date,
        isCancelled,
        createdAt,
      ];
}

