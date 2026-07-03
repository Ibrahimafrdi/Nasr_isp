import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_movement_entity.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/add_inventory_item.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/addstock_inventory_item.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/delete_inventory_item.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/get_inventory_items.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/getstock_inventory.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/update_inventory_item.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final GetInventoryItems getInventoryItems;
  final AddInventoryItem addInventoryItem;
  final UpdateInventoryItem updateInventoryItem;
  final DeleteInventoryItem deleteInventoryItem;
  final AddStockMovement addStockMovement;
  final GetStockMovements getStockMovements;

  InventoryBloc({
    required this.getInventoryItems,
    required this.addInventoryItem,
    required this.updateInventoryItem,
    required this.deleteInventoryItem,
    required this.addStockMovement,
    required this.getStockMovements,
  }) : super(InventoryInitial()) {
    on<LoadInventoryItems>(_onLoadInventoryItems);
    on<AddInventoryItemEvent>(_onAddInventoryItem);
    on<UpdateInventoryItemEvent>(_onUpdateInventoryItem);
    on<DeleteInventoryItemEvent>(_onDeleteInventoryItem);
    on<AddStockMovementEvent>(_onAddStockMovement);
    on<LoadStockMovements>(_onLoadStockMovements);
  }

  Future<void> _onLoadInventoryItems(
    LoadInventoryItems event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      final items = await getInventoryItems();
      emit(InventoryLoaded(items));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onAddInventoryItem(
    AddInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await addInventoryItem(event.item);
      final items = await getInventoryItems();
      emit(InventoryLoaded(items));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onUpdateInventoryItem(
    UpdateInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await updateInventoryItem(event.item);
      final items = await getInventoryItems();
      emit(InventoryLoaded(items));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onDeleteInventoryItem(
    DeleteInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await deleteInventoryItem(event.itemId);
      final items = await getInventoryItems();
      emit(InventoryLoaded(items));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onAddStockMovement(
    AddStockMovementEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await addStockMovement(event.itemId, event.movement);
      final items = await getInventoryItems();
      emit(InventoryLoaded(items));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onLoadStockMovements(
    LoadStockMovements event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      final movements = await getStockMovements(event.itemId);
      emit(StockMovementsLoaded(event.itemId, movements));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }
}
