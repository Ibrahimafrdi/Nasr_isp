import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/features/packages/domain/usecases/add_package.dart';
import 'package:nasr_isp/features/packages/domain/usecases/get_packages.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_event.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_state.dart';

class PackagesBloc extends Bloc<PackagesEvent, PackagesState> {
  final GetPackages getPackages;
  final AddPackage addPackage;

  PackagesBloc({
    required this.getPackages,
    required this.addPackage,
  }) : super(const PackagesInitial()) {
    on<LoadPackagesEvent>(_onLoadPackages);
    on<AddPackageEvent>(_onAddPackage);
  }

  Future<void> _onLoadPackages(
    LoadPackagesEvent event,
    Emitter<PackagesState> emit,
  ) async {
    emit(const PackagesLoading());
    try {
      final packages = await getPackages();
      emit(PackagesLoaded(packages: packages));
    } catch (e) {
      emit(PackagesError(message: 'Failed to load packages: $e'));
    }
  }

  Future<void> _onAddPackage(
    AddPackageEvent event,
    Emitter<PackagesState> emit,
  ) async {
    try {
      await addPackage(event.package);
      add(const LoadPackagesEvent());
    } catch (e) {
      emit(PackagesError(message: 'Failed to add package: $e'));
    }
  }
}
