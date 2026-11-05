import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/inventory/data/models/inventory_item_model.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_detail_entity.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_entity.dart';

abstract class SupplierRepository {
  Future<String> addSupplier(SupplierEntity supplier);
  Future<void> updateSupplier(SupplierEntity supplier);
  Future<void> deactivateSupplier(String supplierId);
  Future<List<SupplierEntity>> getSuppliers({bool? activeOnly});
  Future<SupplierDetailEntity> getSupplierDetail(String supplierId);
  Future<void> addSupplierPayment({
    required String supplierId,
    required String purchaseId,
    required double amount,
    required PaymentMethod method,
    DateTime? date,
    String? notes,
  });
  Future<void> cancelPurchase(String purchaseId, {String? performedBy});
  Future<void> recordStockPurchase({
    required String supplierId,
    required String itemId,
    required String itemName,
    required int quantity,
    required double unitCost,
    double paidNow = 0.0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    DateTime? date,
    String? invoiceNo,
    String? notes,
    String? performedBy,
    InventoryItemModel? inventoryItem,
    bool isNewItem = false,
  });
}

