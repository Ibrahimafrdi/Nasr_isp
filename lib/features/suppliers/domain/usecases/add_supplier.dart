import 'package:nasr_isp/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:nasr_isp/features/suppliers/domain/repositories/supplier_repository.dart';

class AddSupplier {
  final SupplierRepository repository;
  AddSupplier(this.repository);

  Future<String> call(SupplierEntity supplier) {
    return repository.addSupplier(supplier);
  }
}

