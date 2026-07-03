// update_inventory_item.dart
import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:nasr_isp/features/inventory/domain/repositories/inventory_repository.dart';

class UpdateInventoryItem {
  final InventoryRepository repository;
  UpdateInventoryItem(this.repository);
  Future<void> call(InventoryItemEntity item) =>
      repository.updateInventoryItem(item);
}
