// get_stock_movements.dart
import 'package:nasr_isp/features/inventory/domain/entities/stock_movement_entity.dart';
import 'package:nasr_isp/features/inventory/domain/repositories/inventory_repository.dart';

class GetStockMovements {
  final InventoryRepository repository;
  GetStockMovements(this.repository);
  Future<List<StockMovementEntity>> call(String itemId) =>
      repository.getStockMovements(itemId);
}
