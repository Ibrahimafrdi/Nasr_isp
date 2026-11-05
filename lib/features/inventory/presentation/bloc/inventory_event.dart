part of 'inventory_bloc.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadInventoryItems extends InventoryEvent {}

class AddInventoryItemEvent extends InventoryEvent {
  final InventoryItemEntity item;
  final String? supplierId;
  final double? unitCost;
  final double paidNow;
  final PaymentMethod paymentMethod;
  final DateTime? purchaseDate;
  final String? invoiceNo;
  final String? purchaseNotes;
  final String? performedBy;

  const AddInventoryItemEvent(
    this.item, {
    this.supplierId,
    this.unitCost,
    this.paidNow = 0.0,
    this.paymentMethod = PaymentMethod.cash,
    this.purchaseDate,
    this.invoiceNo,
    this.purchaseNotes,
    this.performedBy,
  });

  @override
  List<Object?> get props => [
    item,
    supplierId,
    unitCost,
    paidNow,
    paymentMethod,
    purchaseDate,
    invoiceNo,
    purchaseNotes,
    performedBy,
  ];
}

class UpdateInventoryItemEvent extends InventoryEvent {
  final InventoryItemEntity item;
  const UpdateInventoryItemEvent(this.item);
  @override
  List<Object?> get props => [item];
}

class DeleteInventoryItemEvent extends InventoryEvent {
  final String itemId;
  const DeleteInventoryItemEvent(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class AddStockMovementEvent extends InventoryEvent {
  final String itemId;
  final StockMovementEntity movement;
  final String? supplierId;
  final double? unitCost;
  final double paidNow;
  final PaymentMethod paymentMethod;
  final DateTime? purchaseDate;
  final String? invoiceNo;
  final String? purchaseNotes;

  const AddStockMovementEvent(
    this.itemId,
    this.movement, {
    this.supplierId,
    this.unitCost,
    this.paidNow = 0.0,
    this.paymentMethod = PaymentMethod.cash,
    this.purchaseDate,
    this.invoiceNo,
    this.purchaseNotes,
  });

  @override
  List<Object?> get props => [
    itemId,
    movement,
    supplierId,
    unitCost,
    paidNow,
    paymentMethod,
    purchaseDate,
    invoiceNo,
    purchaseNotes,
  ];
}

class LoadStockMovements extends InventoryEvent {
  final String itemId;
  const LoadStockMovements(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class IssueStockEvent extends InventoryEvent {
  final StockIssueEntity issue;
  const IssueStockEvent(this.issue);
  @override
  List<Object?> get props => [issue];
}
