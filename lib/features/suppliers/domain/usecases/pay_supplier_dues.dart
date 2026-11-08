import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/suppliers/domain/repositories/supplier_repository.dart';

/// Pays a supplier against their total outstanding balance. The amount is
/// applied to the oldest unpaid invoices first.
class PaySupplierDues {
  final SupplierRepository repository;
  PaySupplierDues(this.repository);

  Future<void> call({
    required String supplierId,
    required double amount,
    required PaymentMethod method,
    DateTime? date,
    String? notes,
  }) {
    return repository.paySupplierDues(
      supplierId: supplierId,
      amount: amount,
      method: method,
      date: date,
      notes: notes,
    );
  }
}
