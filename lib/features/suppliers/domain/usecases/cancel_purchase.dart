import 'package:nasr_isp/features/suppliers/domain/repositories/supplier_repository.dart';

class CancelPurchase {
  final SupplierRepository repository;
  CancelPurchase(this.repository);

  Future<void> call(String purchaseId, {String? performedBy}) {
    return repository.cancelPurchase(purchaseId, performedBy: performedBy);
  }
}

