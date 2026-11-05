import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/suppliers/domain/repositories/supplier_repository.dart';

class AddSupplierPayment {
  final SupplierRepository repository;
  AddSupplierPayment(this.repository);

  Future<void> call({
    required String supplierId,
    required String purchaseId,
    required double amount,
    required PaymentMethod method,
    DateTime? date,
    String? notes,
  }) {
    return repository.addSupplierPayment(
      supplierId: supplierId,
      purchaseId: purchaseId,
      amount: amount,
      method: method,
      date: date,
      notes: notes,
    );
  }
}

