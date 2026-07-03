import 'package:equatable/equatable.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';

abstract class PackagesEvent extends Equatable {
  const PackagesEvent();

  @override
  List<Object?> get props => [];
}

class LoadPackages extends PackagesEvent {
  final ConnectionType? filterByType;
  final bool? activeOnly;

  const LoadPackages({this.filterByType, this.activeOnly});

  @override
  List<Object?> get props => [filterByType, activeOnly];
}

class AddPackageRequested extends PackagesEvent {
  final PackageEntity package;

  const AddPackageRequested(this.package);

  @override
  List<Object?> get props => [package];
}

class UpdatePackageRequested extends PackagesEvent {
  final PackageEntity package;

  const UpdatePackageRequested(this.package);

  @override
  List<Object?> get props => [package];
}

class DeletePackageRequested extends PackagesEvent {
  final String id;

  const DeletePackageRequested(this.id);

  @override
  List<Object?> get props => [id];
}

// ── Legacy alias ─────────────────────────────────────────────────────────────
// Kept for backward compatibility with existing code that uses LoadPackagesEvent
// and AddPackageEvent (e.g. service_locator, PackagesPage).
class LoadPackagesEvent extends LoadPackages {
  const LoadPackagesEvent() : super();
}

class AddPackageEvent extends AddPackageRequested {
  const AddPackageEvent(super.package);
}
