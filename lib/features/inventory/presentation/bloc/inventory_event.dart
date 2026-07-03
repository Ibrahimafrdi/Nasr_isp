part of 'inventory_bloc.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadInventoryItems extends InventoryEvent {}

class AddInventoryItemEvent extends InventoryEvent {
  final InventoryItemEntity item;
  const AddInventoryItemEvent(this.item);
  @override
  List<Object?> get props => [item];
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
  const AddStockMovementEvent(this.itemId, this.movement);
  @override
  List<Object?> get props => [itemId, movement];
}

class LoadStockMovements extends InventoryEvent {
  final String itemId;
  const LoadStockMovements(this.itemId);
  @override
  List<Object?> get props => [itemId];
}
