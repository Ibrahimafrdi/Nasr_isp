import 'package:nasr_isp/features/suppliers/domain/repositories/supplier_repository.dart';

class DeactivateSupplier {
  final SupplierRepository repository;
  DeactivateSupplier(this.repository);

  Future<void> call(String supplierId) {
    return repository.deactivateSupplier(supplierId);
  }
}

