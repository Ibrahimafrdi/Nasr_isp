import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/domain/repositories/package_repository.dart';

class UpdatePackage {
  final PackageRepository repository;

  UpdatePackage(this.repository);

  Future<void> call(PackageEntity package) =>
      repository.updatePackage(package);
}
