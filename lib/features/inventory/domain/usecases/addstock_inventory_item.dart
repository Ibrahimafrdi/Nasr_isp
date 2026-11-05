import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_movement_entity.dart';
import 'package:nasr_isp/features/inventory/domain/repositories/inventory_repository.dart';

class AddStockMovement {
  final InventoryRepository repository;

  AddStockMovement(this.repository);

  Future<void> call(
    String itemId,
    StockMovementEntity movement, {
    String? supplierId,
    double? unitCost,
    double paidNow = 0.0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    DateTime? purchaseDate,
    String? invoiceNo,
    String? purchaseNotes,
  }) =>
      repository.addStockMovement(
        itemId,
        movement,
        supplierId: supplierId,
        unitCost: unitCost,
        paidNow: paidNow,
        paymentMethod: paymentMethod,
        purchaseDate: purchaseDate,
        invoiceNo: invoiceNo,
        purchaseNotes: purchaseNotes,
      );
}
