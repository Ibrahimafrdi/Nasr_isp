import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/features/suppliers/domain/usecases/add_supplier.dart';
import 'package:nasr_isp/features/suppliers/domain/usecases/add_supplier_payment.dart';
import 'package:nasr_isp/features/suppliers/domain/usecases/cancel_purchase.dart';
import 'package:nasr_isp/features/suppliers/domain/usecases/deactivate_supplier.dart';
import 'package:nasr_isp/features/suppliers/domain/usecases/get_supplier_detail.dart';
import 'package:nasr_isp/features/suppliers/domain/usecases/get_suppliers.dart';
import 'package:nasr_isp/features/suppliers/domain/usecases/update_supplier.dart';
import 'package:nasr_isp/features/suppliers/presentation/bloc/supplier_event.dart';
import 'package:nasr_isp/features/suppliers/presentation/bloc/supplier_state.dart';

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final AddSupplier addSupplier;
  final UpdateSupplier updateSupplier;
  final DeactivateSupplier deactivateSupplier;
  final GetSuppliers getSuppliers;
  final GetSupplierDetail getSupplierDetail;
  final AddSupplierPayment addSupplierPayment;
  final CancelPurchase cancelPurchase;

  SupplierBloc({
    required this.addSupplier,
    required this.updateSupplier,
    required this.deactivateSupplier,
    required this.getSuppliers,
    required this.getSupplierDetail,
    required this.addSupplierPayment,
    required this.cancelPurchase,
  }) : super(SupplierInitial()) {
    on<LoadSuppliersEvent>(_onLoadSuppliers);
    on<LoadSupplierDetailEvent>(_onLoadSupplierDetail);
    on<AddSupplierEvent>(_onAddSupplier);
    on<UpdateSupplierEvent>(_onUpdateSupplier);
    on<DeactivateSupplierEvent>(_onDeactivateSupplier);
    on<AddSupplierPaymentEvent>(_onAddSupplierPayment);
    on<CancelPurchaseEvent>(_onCancelPurchase);
  }

  Future<void> _onLoadSuppliers(
    LoadSuppliersEvent event,
    Emitter<SupplierState> emit,
  ) async {
    emit(SupplierLoading());
    try {
      final list = await getSuppliers(activeOnly: event.activeOnly);
      emit(SuppliersLoaded(list));
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> _onLoadSupplierDetail(
    LoadSupplierDetailEvent event,
    Emitter<SupplierState> emit,
  ) async {
    emit(SupplierLoading());
    try {
      final detail = await getSupplierDetail(event.supplierId);
      emit(SupplierDetailLoaded(detail));
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> _onAddSupplier(
    AddSupplierEvent event,
    Emitter<SupplierState> emit,
  ) async {
    emit(SupplierLoading());
    try {
      final newId = await addSupplier(event.supplier);
      emit(SupplierActionSuccess('Supplier added successfully', createdSupplierId: newId));
      final list = await getSuppliers();
      emit(SuppliersLoaded(list));
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> _onUpdateSupplier(
    UpdateSupplierEvent event,
    Emitter<SupplierState> emit,
  ) async {
    emit(SupplierLoading());
    try {
      await updateSupplier(event.supplier);
      emit(const SupplierActionSuccess('Supplier updated successfully'));
      final detail = await getSupplierDetail(event.supplier.id);
      emit(SupplierDetailLoaded(detail));
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> _onDeactivateSupplier(
    DeactivateSupplierEvent event,
    Emitter<SupplierState> emit,
  ) async {
    emit(SupplierLoading());
    try {
      await deactivateSupplier(event.supplierId);
      emit(const SupplierActionSuccess('Supplier deactivated successfully'));
      final list = await getSuppliers();
      emit(SuppliersLoaded(list));
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> _onAddSupplierPayment(
    AddSupplierPaymentEvent event,
    Emitter<SupplierState> emit,
  ) async {
    emit(SupplierLoading());
    try {
      await addSupplierPayment(
        supplierId: event.supplierId,
        purchaseId: event.purchaseId,
        amount: event.amount,
        method: event.method,
        date: event.date,
        notes: event.notes,
      );
      emit(const SupplierActionSuccess('Payment recorded successfully'));
      final detail = await getSupplierDetail(event.supplierId);
      emit(SupplierDetailLoaded(detail));
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> _onCancelPurchase(
    CancelPurchaseEvent event,
    Emitter<SupplierState> emit,
  ) async {
    emit(SupplierLoading());
    try {
      await cancelPurchase(event.purchaseId, performedBy: event.performedBy);
      emit(const SupplierActionSuccess('Purchase cancelled successfully'));
      final detail = await getSupplierDetail(event.supplierId);
      emit(SupplierDetailLoaded(detail));
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }
}

