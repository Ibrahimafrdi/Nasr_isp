import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_movement_entity.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_issue_entity.dart';

abstract class InventoryRepository {
  Future<void> addInventoryItem(
    InventoryItemEntity item, {
    String? supplierId,
    double? unitCost,
    double paidNow = 0.0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    DateTime? purchaseDate,
    String? invoiceNo,
    String? purchaseNotes,
    String? performedBy,
  });
  Future<List<InventoryItemEntity>> getInventoryItems();
  Future<void> updateInventoryItem(InventoryItemEntity item);
  Future<void> deleteInventoryItem(String itemId);
  Future<void> addStockMovement(
    String itemId,
    StockMovementEntity movement, {
    String? supplierId,
    double? unitCost,
    double paidNow = 0.0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    DateTime? purchaseDate,
    String? invoiceNo,
    String? purchaseNotes,
  });
  Future<List<StockMovementEntity>> getStockMovements(String itemId);
  Future<void> issueStock(StockIssueEntity issue);
  Future<List<StockIssueEntity>> getStockIssues({
    DateTime? startDate,
    DateTime? endDate,
  });
}
