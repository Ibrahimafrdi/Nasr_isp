import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:nasr_isp/features/inventory/domain/repositories/inventory_repository.dart';

class AddInventoryItem {
  final InventoryRepository repository;

  AddInventoryItem(this.repository);

  Future<void> call(
    InventoryItemEntity item, {
    String? supplierId,
    double? unitCost,
    double paidNow = 0.0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    DateTime? purchaseDate,
    String? invoiceNo,
    String? purchaseNotes,
    String? performedBy,
  }) async {
    return repository.addInventoryItem(
      item,
      supplierId: supplierId,
      unitCost: unitCost,
      paidNow: paidNow,
      paymentMethod: paymentMethod,
      purchaseDate: purchaseDate,
      invoiceNo: invoiceNo,
      purchaseNotes: purchaseNotes,
      performedBy: performedBy,
    );
  }
}
