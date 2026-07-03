import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/features/packages/domain/usecases/add_package.dart';
import 'package:nasr_isp/features/packages/domain/usecases/delete_package.dart';
import 'package:nasr_isp/features/packages/domain/usecases/get_packages.dart';
import 'package:nasr_isp/features/packages/domain/usecases/update_package.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_event.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_state.dart';

class PackagesBloc extends Bloc<PackagesEvent, PackagesState> {
  final GetPackages getPackages;
  final AddPackage addPackage;
  final UpdatePackage updatePackage;
  final DeletePackage deletePackage;

  PackagesBloc({
    required this.getPackages,
    required this.addPackage,
    required this.updatePackage,
    required this.deletePackage,
  }) : super(const PackagesInitial()) {
    on<LoadPackages>(_onLoadPackages);
    on<AddPackageRequested>(_onAddPackage);
    on<UpdatePackageRequested>(_onUpdatePackage);
    on<DeletePackageRequested>(_onDeletePackage);
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _onLoadPackages(
    LoadPackages event,
    Emitter<PackagesState> emit,
  ) async {
    emit(const PackagesLoading());
    try {
      final packages = await getPackages(
        filterByType: event.filterByType,
        activeOnly: event.activeOnly,
      );
      emit(PackagesLoaded(
        packages: packages,
        activeFilter: event.filterByType,
      ));
    } catch (e) {
      emit(PackagesError(message: 'Failed to load packages: $e'));
    }
  }

  // ── Add ───────────────────────────────────────────────────────────────────

  Future<void> _onAddPackage(
    AddPackageRequested event,
    Emitter<PackagesState> emit,
  ) async {
    try {
      await addPackage(event.package);
      emit(const PackageActionSuccess(message: 'Package added successfully'));
      add(const LoadPackages());
    } catch (e) {
      emit(PackagesError(message: 'Failed to add package: $e'));
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> _onUpdatePackage(
    UpdatePackageRequested event,
    Emitter<PackagesState> emit,
  ) async {
    try {
      await updatePackage(event.package);
      emit(const PackageActionSuccess(message: 'Package updated successfully'));
      add(const LoadPackages());
    } catch (e) {
      emit(PackagesError(message: 'Failed to update package: $e'));
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _onDeletePackage(
    DeletePackageRequested event,
    Emitter<PackagesState> emit,
  ) async {
    try {
      await deletePackage(event.id);
      emit(const PackageActionSuccess(message: 'Package deleted successfully'));
      add(const LoadPackages());
    } catch (e) {
      emit(PackagesError(message: 'Failed to delete package: $e'));
    }
  }
}
