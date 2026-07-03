import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:nasr_isp/features/inventory/domain/repositories/inventory_repository.dart';

class GetInventoryItems {
  final InventoryRepository repository;

  GetInventoryItems(this.repository);

  Future<List<InventoryItemEntity>> call() async {
    return repository.getInventoryItems();
  }
}
