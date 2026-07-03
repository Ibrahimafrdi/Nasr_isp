// add_stock_movement.dart
import 'package:nasr_isp/features/inventory/domain/entities/stock_movement_entity.dart';
import 'package:nasr_isp/features/inventory/domain/repositories/inventory_repository.dart';

class AddStockMovement {
  final InventoryRepository repository;
  AddStockMovement(this.repository);
  Future<void> call(String itemId, StockMovementEntity movement) =>
      repository.addStockMovement(itemId, movement);
}
