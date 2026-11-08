import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/inventory/data/models/inventory_item_model.dart';
import 'package:nasr_isp/features/suppliers/data/datasources/supplier_remote_data_source.dart';
import 'package:nasr_isp/features/suppliers/data/models/supplier_model.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_detail_entity.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:nasr_isp/features/suppliers/domain/repositories/supplier_repository.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final SupplierRemoteDataSource remoteDataSource;

  SupplierRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> addSupplier(SupplierEntity supplier) {
    final model = SupplierModel(
      id: supplier.id,
      name: supplier.name,
      phone: supplier.phone,
      address: supplier.address,
      notes: supplier.notes,
      isActive: supplier.isActive,
      totalPurchased: supplier.totalPurchased,
      totalPaid: supplier.totalPaid,
      pendingBalance: supplier.pendingBalance,
      createdAt: supplier.createdAt,
    );
    return remoteDataSource.addSupplier(model);
  }

  @override
  Future<void> updateSupplier(SupplierEntity supplier) {
    final model = SupplierModel(
      id: supplier.id,
      name: supplier.name,
      phone: supplier.phone,
      address: supplier.address,
      notes: supplier.notes,
      isActive: supplier.isActive,
      totalPurchased: supplier.totalPurchased,
      totalPaid: supplier.totalPaid,
      pendingBalance: supplier.pendingBalance,
      createdAt: supplier.createdAt,
    );
    return remoteDataSource.updateSupplier(model);
  }

  @override
  Future<void> deactivateSupplier(String supplierId) {
    return remoteDataSource.deactivateSupplier(supplierId);
  }

  @override
  Future<List<SupplierEntity>> getSuppliers({bool? activeOnly}) {
    return remoteDataSource.getSuppliers(activeOnly: activeOnly);
  }

  @override
  Future<SupplierDetailEntity> getSupplierDetail(String supplierId) {
    return remoteDataSource.getSupplierDetail(supplierId);
  }

  @override
  Future<void> addSupplierPayment({
    required String supplierId,
    required String purchaseId,
    required double amount,
    required PaymentMethod method,
    DateTime? date,
    String? notes,
  }) {
    return remoteDataSource.addSupplierPayment(
      supplierId: supplierId,
      purchaseId: purchaseId,
      amount: amount,
      method: method,
      date: date,
      notes: notes,
    );
  }

  @override
  Future<void> paySupplierDues({
    required String supplierId,
    required double amount,
    required PaymentMethod method,
    DateTime? date,
    String? notes,
  }) {
    return remoteDataSource.paySupplierDues(
      supplierId: supplierId,
      amount: amount,
      method: method,
      date: date,
      notes: notes,
    );
  }

  @override
  Future<void> cancelPurchase(String purchaseId, {String? performedBy}) {
    return remoteDataSource.cancelPurchase(
      purchaseId,
      performedBy: performedBy,
    );
  }

  @override
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
  }) {
    return remoteDataSource.recordStockPurchase(
      supplierId: supplierId,
      itemId: itemId,
      itemName: itemName,
      quantity: quantity,
      unitCost: unitCost,
      paidNow: paidNow,
      paymentMethod: paymentMethod,
      date: date,
      invoiceNo: invoiceNo,
      notes: notes,
      performedBy: performedBy,
      inventoryItem: inventoryItem,
      isNewItem: isNewItem,
    );
  }
}
