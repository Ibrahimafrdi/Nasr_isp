import 'package:equatable/equatable.dart';
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

  const PackagesLoaded({required this.packages});

  @override
  List<Object?> get props => [packages];
}

class PackagesError extends PackagesState {
  final String message;

  const PackagesError({required this.message});

  @override
  List<Object?> get props => [message];
}
