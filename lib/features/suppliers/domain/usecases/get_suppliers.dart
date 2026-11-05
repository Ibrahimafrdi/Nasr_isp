import 'package:nasr_isp/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:nasr_isp/features/suppliers/domain/repositories/supplier_repository.dart';

class GetSuppliers {
  final SupplierRepository repository;
  GetSuppliers(this.repository);

  Future<List<SupplierEntity>> call({bool? activeOnly}) {
    return repository.getSuppliers(activeOnly: activeOnly);
  }
}

