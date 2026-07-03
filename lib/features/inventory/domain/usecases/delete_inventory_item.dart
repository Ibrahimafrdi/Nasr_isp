// delete_inventory_item.dart
import 'package:nasr_isp/features/inventory/domain/repositories/inventory_repository.dart';

class DeleteInventoryItem {
  final InventoryRepository repository;
  DeleteInventoryItem(this.repository);
  Future<void> call(String itemId) => repository.deleteInventoryItem(itemId);
}
