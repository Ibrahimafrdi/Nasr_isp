import 'package:equatable/equatable.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';

abstract class PackagesEvent extends Equatable {
  const PackagesEvent();

  @override
  List<Object?> get props => [];
}

class LoadPackagesEvent extends PackagesEvent {
  const LoadPackagesEvent();
}

class AddPackageEvent extends PackagesEvent {
  final PackageEntity package;

  const AddPackageEvent(this.package);

  @override
  List<Object?> get props => [package];
}
