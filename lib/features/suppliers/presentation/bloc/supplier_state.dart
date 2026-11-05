import 'package:equatable/equatable.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_detail_entity.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_entity.dart';

abstract class SupplierState extends Equatable {
  const SupplierState();

  @override
  List<Object?> get props => [];
}

class SupplierInitial extends SupplierState {}

class SupplierLoading extends SupplierState {}

class SuppliersLoaded extends SupplierState {
  final List<SupplierEntity> suppliers;
  const SuppliersLoaded(this.suppliers);

  @override
  List<Object?> get props => [suppliers];
}

class SupplierDetailLoaded extends SupplierState {
  final SupplierDetailEntity detail;
  const SupplierDetailLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
}

class SupplierActionSuccess extends SupplierState {
  final String message;
  final String? createdSupplierId;

  const SupplierActionSuccess(this.message, {this.createdSupplierId});

  @override
  List<Object?> get props => [message, createdSupplierId];
}

class SupplierError extends SupplierState {
  final String message;
  const SupplierError(this.message);

  @override
  List<Object?> get props => [message];
}

