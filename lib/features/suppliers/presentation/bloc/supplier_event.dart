import 'package:equatable/equatable.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_entity.dart';

abstract class SupplierEvent extends Equatable {
  const SupplierEvent();

  @override
  List<Object?> get props => [];
}

class LoadSuppliersEvent extends SupplierEvent {
  final bool? activeOnly;
  const LoadSuppliersEvent({this.activeOnly});

  @override
  List<Object?> get props => [activeOnly];
}

class LoadSupplierDetailEvent extends SupplierEvent {
  final String supplierId;
  const LoadSupplierDetailEvent(this.supplierId);

  @override
  List<Object?> get props => [supplierId];
}

class AddSupplierEvent extends SupplierEvent {
  final SupplierEntity supplier;
  const AddSupplierEvent(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class UpdateSupplierEvent extends SupplierEvent {
  final SupplierEntity supplier;
  const UpdateSupplierEvent(this.supplier);

  @override
  List<Object?> get props => [supplier];
}

class DeactivateSupplierEvent extends SupplierEvent {
  final String supplierId;
  const DeactivateSupplierEvent(this.supplierId);

  @override
  List<Object?> get props => [supplierId];
}

class AddSupplierPaymentEvent extends SupplierEvent {
  final String supplierId;
  final String purchaseId;
  final double amount;
  final PaymentMethod method;
  final DateTime? date;
  final String? notes;

  const AddSupplierPaymentEvent({
    required this.supplierId,
    required this.purchaseId,
    required this.amount,
    required this.method,
    this.date,
    this.notes,
  });

  @override
  List<Object?> get props => [supplierId, purchaseId, amount, method, date, notes];
}

class CancelPurchaseEvent extends SupplierEvent {
  final String purchaseId;
  final String supplierId;
  final String? performedBy;

  const CancelPurchaseEvent({
    required this.purchaseId,
    required this.supplierId,
    this.performedBy,
  });

  @override
  List<Object?> get props => [purchaseId, supplierId, performedBy];
}

