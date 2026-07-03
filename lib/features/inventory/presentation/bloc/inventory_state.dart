part of 'inventory_bloc.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();
  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<InventoryItemEntity> items;
  final List<InventoryItemEntity> lowStockItems;

  InventoryLoaded(this.items)
    : lowStockItems = items
          .where((i) => i.quantityInStock <= i.reorderLevel)
          .toList();

  @override
  List<Object?> get props => [items];
}

class StockMovementsLoaded extends InventoryState {
  final String itemId;
  final List<StockMovementEntity> movements;
  const StockMovementsLoaded(this.itemId, this.movements);
  @override
  List<Object?> get props => [itemId, movements];
}

class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);
  @override
  List<Object?> get props => [message];
}
