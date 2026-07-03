import 'package:equatable/equatable.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';

abstract class PackagesState extends Equatable {
  const PackagesState();

  @override
  List<Object?> get props => [];
}

class PackagesInitial extends PackagesState {
  const PackagesInitial();
}

class PackagesLoading extends PackagesState {
  const PackagesLoading();
}

class PackagesLoaded extends PackagesState {
  final List<PackageEntity> packages;
  final ConnectionType? activeFilter;

  const PackagesLoaded({required this.packages, this.activeFilter});

  @override
  List<Object?> get props => [packages, activeFilter];
}

class PackagesError extends PackagesState {
  final String message;

  const PackagesError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Emitted after a successful add / update / delete action.
/// The UI should show a snackbar and then re-dispatch LoadPackages.
class PackageActionSuccess extends PackagesState {
  final String message;

  const PackageActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
