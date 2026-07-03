import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_movement_entity.dart';

abstract class InventoryRepository {
  Future<void> addInventoryItem(InventoryItemEntity item);
  Future<List<InventoryItemEntity>> getInventoryItems();
  Future<void> updateInventoryItem(InventoryItemEntity item);
  Future<void> deleteInventoryItem(String itemId);
  Future<void> addStockMovement(String itemId, StockMovementEntity movement);
  Future<List<StockMovementEntity>> getStockMovements(String itemId);
}
