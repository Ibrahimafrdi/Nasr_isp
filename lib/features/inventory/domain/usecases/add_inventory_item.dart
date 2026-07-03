import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:nasr_isp/features/inventory/domain/repositories/inventory_repository.dart';

class AddInventoryItem {
  final InventoryRepository repository;

  AddInventoryItem(this.repository);

  Future<void> call(InventoryItemEntity item) async {
    return repository.addInventoryItem(item);
  }
}
