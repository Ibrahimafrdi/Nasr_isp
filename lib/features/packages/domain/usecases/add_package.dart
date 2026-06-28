import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/domain/repositories/package_repository.dart';

class AddPackage {
  final PackageRepository repository;

  AddPackage(this.repository);

  Future<void> call(PackageEntity package) async {
    return repository.addPackage(package);
  }
}
