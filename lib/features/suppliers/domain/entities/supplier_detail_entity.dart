import 'package:equatable/equatable.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_payment_entity.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_purchase_entity.dart';

class SupplierDetailEntity extends Equatable {
  final SupplierEntity supplier;
  final List<SupplierPurchaseEntity> purchases;
  final List<SupplierPaymentEntity> payments;

  const SupplierDetailEntity({
    required this.supplier,
    required this.purchases,
    required this.payments,
  });

  @override
  List<Object?> get props => [supplier, purchases, payments];
}

