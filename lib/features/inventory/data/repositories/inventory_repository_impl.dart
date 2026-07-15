import 'package:nasr_isp/features/inventory/data/datasources/inventory_remote_data_source.dart';
import 'package:nasr_isp/features/inventory/data/models/inventory_item_model.dart';
import 'package:nasr_isp/features/inventory/data/models/stock_movement_model.dart';
import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_movement_entity.dart';
import 'package:nasr_isp/features/inventory/domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;

  InventoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> addInventoryItem(InventoryItemEntity item) async {
    final model = InventoryItemModel(
      id: item.id,
      name: item.name,
      category: item.category,
      unit: item.unit,
      quantityInStock: item.quantityInStock,
      reorderLevel: item.reorderLevel,
      unitCost: item.unitCost,
      sellPrice: item.sellPrice,
      supplier: item.supplier,
      notes: item.notes,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      connectionType: item.connectionType,
    );
    await remoteDataSource.addInventoryItem(model);
  }

  @override
  Future<List<InventoryItemEntity>> getInventoryItems() async {
    return await remoteDataSource.getInventoryItems();
  }

  @override
  Future<void> updateInventoryItem(InventoryItemEntity item) async {
    final model = InventoryItemModel(
      id: item.id,
      name: item.name,
      category: item.category,
      unit: item.unit,
      quantityInStock: item.quantityInStock,
      reorderLevel: item.reorderLevel,
      unitCost: item.unitCost,
      sellPrice: item.sellPrice,
      supplier: item.supplier,
      notes: item.notes,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      connectionType: item.connectionType,
    );
    await remoteDataSource.updateInventoryItem(model);
  }

  @override
  Future<void> deleteInventoryItem(String itemId) async {
    await remoteDataSource.deleteInventoryItem(itemId);
  }

  @override
  Future<void> addStockMovement(String itemId, StockMovementEntity movement) async {
    final model = StockMovementModel(
      id: movement.id,
      itemId: movement.itemId,
      type: movement.type,
      quantity: movement.quantity,
      reason: movement.reason,
      date: movement.date,
      performedBy: movement.performedBy,
    );
    await remoteDataSource.addStockMovement(itemId, model);
  }

  @override
  Future<List<StockMovementEntity>> getStockMovements(String itemId) async {
    return await remoteDataSource.getStockMovements(itemId);
  }
}
