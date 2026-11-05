import 'package:nasr_isp/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:nasr_isp/features/suppliers/domain/repositories/supplier_repository.dart';

class UpdateSupplier {
  final SupplierRepository repository;
  UpdateSupplier(this.repository);

  Future<void> call(SupplierEntity supplier) {
    return repository.updateSupplier(supplier);
  }
}

