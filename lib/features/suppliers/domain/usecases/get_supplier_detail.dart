import 'package:nasr_isp/features/suppliers/domain/entities/supplier_detail_entity.dart';
import 'package:nasr_isp/features/suppliers/domain/repositories/supplier_repository.dart';

class GetSupplierDetail {
  final SupplierRepository repository;
  GetSupplierDetail(this.repository);

  Future<SupplierDetailEntity> call(String supplierId) {
    return repository.getSupplierDetail(supplierId);
  }
}

