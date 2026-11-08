import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_movement_entity.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_issue_entity.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/add_inventory_item.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/addstock_inventory_item.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/delete_inventory_item.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/get_inventory_items.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/getstock_inventory.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/update_inventory_item.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/issue_stock.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/get_stock_issues.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final GetInventoryItems getInventoryItems;
  final AddInventoryItem addInventoryItem;
  final UpdateInventoryItem updateInventoryItem;
  final DeleteInventoryItem deleteInventoryItem;
  final AddStockMovement addStockMovement;
  final GetStockMovements getStockMovements;
  final IssueStock issueStock;
  final GetStockIssues getStockIssues;

  InventoryBloc({
    required this.getInventoryItems,
    required this.addInventoryItem,
    required this.updateInventoryItem,
    required this.deleteInventoryItem,
    required this.addStockMovement,
    required this.getStockMovements,
    required this.issueStock,
    required this.getStockIssues,
  }) : super(InventoryInitial()) {
    on<LoadInventoryItems>(_onLoadInventoryItems);
    on<AddInventoryItemEvent>(_onAddInventoryItem);
    on<UpdateInventoryItemEvent>(_onUpdateInventoryItem);
    on<DeleteInventoryItemEvent>(_onDeleteInventoryItem);
    on<AddStockMovementEvent>(_onAddStockMovement);
    on<LoadStockMovements>(_onLoadStockMovements);
    on<IssueStockEvent>(_onIssueStock);
  }

  Future<void> _onLoadInventoryItems(
    LoadInventoryItems event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      await _emitInventory(emit);
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onAddInventoryItem(
    AddInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await addInventoryItem(
        event.item,
        supplierId: event.supplierId,
        unitCost: event.unitCost,
        paidNow: event.paidNow,
        paymentMethod: event.paymentMethod,
        purchaseDate: event.purchaseDate,
        invoiceNo: event.invoiceNo,
        purchaseNotes: event.purchaseNotes,
        performedBy: event.performedBy,
      );
      await _emitInventory(emit);
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
      await _emitInventory(emit);
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
      await _emitInventory(emit);
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onAddStockMovement(
    AddStockMovementEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await addStockMovement(
        event.itemId,
        event.movement,
        supplierId: event.supplierId,
        unitCost: event.unitCost,
        paidNow: event.paidNow,
        paymentMethod: event.paymentMethod,
        purchaseDate: event.purchaseDate,
        invoiceNo: event.invoiceNo,
        purchaseNotes: event.purchaseNotes,
      );
      await _emitInventory(emit);
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

  Future<void> _onIssueStock(
    IssueStockEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await issueStock(event.issue);
      await _emitInventory(emit);
    } catch (e) {
      emit(InventoryError(_readableError(e)));
    }
  }

  /// On web, errors thrown inside a Firestore transaction arrive boxed
  /// ("Dart exception thrown from converted Future..."). Unwrap the real one.
  String _readableError(Object e) {
    try {
      final inner = (e as dynamic).error;
      if (inner != null) return _clean(inner.toString());
    } catch (_) {}
    return _clean(e.toString());
  }

  String _clean(String message) => message
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('Exception: ', '');

  Future<void> _emitInventory(Emitter<InventoryState> emit) async {
    final results = await Future.wait([getInventoryItems(), getStockIssues()]);
    final issues = (results[1] as List<StockIssueEntity>)
      ..sort((a, b) => b.date.compareTo(a.date));
    emit(InventoryLoaded(results[0] as List<InventoryItemEntity>, issues));
  }
}
