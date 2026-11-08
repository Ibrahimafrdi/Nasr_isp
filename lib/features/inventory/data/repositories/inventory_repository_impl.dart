import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/inventory/data/datasources/inventory_remote_data_source.dart';
import 'package:nasr_isp/features/inventory/data/models/inventory_item_model.dart';
import 'package:nasr_isp/features/inventory/data/models/stock_movement_model.dart';
import 'package:nasr_isp/features/inventory/data/models/stock_issue_model.dart';
import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_movement_entity.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_issue_entity.dart';
import 'package:nasr_isp/features/inventory/domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;

  InventoryRepositoryImpl({required this.remoteDataSource});

  @override
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
  }) async {
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
    await remoteDataSource.addInventoryItem(
      model,
      supplierId: supplierId,
      unitCost: unitCost,
      paidNow: paidNow,
      paymentMethod: paymentMethod,
      purchaseDate: purchaseDate,
      invoiceNo: invoiceNo,
      purchaseNotes: purchaseNotes,
      performedBy: performedBy,
    );
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
  }) async {
    final model = StockMovementModel(
      id: movement.id,
      itemId: movement.itemId,
      type: movement.type,
      quantity: movement.quantity,
      reason: movement.reason,
      date: movement.date,
      performedBy: movement.performedBy,
    );
    await remoteDataSource.addStockMovement(
      itemId,
      model,
      supplierId: supplierId,
      unitCost: unitCost,
      paidNow: paidNow,
      paymentMethod: paymentMethod,
      purchaseDate: purchaseDate,
      invoiceNo: invoiceNo,
      purchaseNotes: purchaseNotes,
    );
  }

  @override
  Future<List<StockMovementEntity>> getStockMovements(String itemId) async {
    return await remoteDataSource.getStockMovements(itemId);
  }

  @override
  Future<void> issueStock(StockIssueEntity issue) async {
    await remoteDataSource.issueStock(
      StockIssueModel(
        id: issue.id,
        itemId: issue.itemId,
        itemName: issue.itemName,
        quantity: issue.quantity,
        unitCost: issue.unitCost,
        purpose: issue.purpose,
        towerName: issue.towerName,
        notes: issue.notes,
        date: issue.date,
        issuedBy: issue.issuedBy,
        createdAt: issue.createdAt,
        salePrice: issue.salePrice,
        buyerName: issue.buyerName,
        customerId: issue.customerId,
        paymentMethod: issue.paymentMethod,
      ),
    );
  }

  @override
  Future<List<StockIssueEntity>> getStockIssues() async =>
      remoteDataSource.getStockIssues();
}
