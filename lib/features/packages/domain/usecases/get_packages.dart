import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/domain/repositories/package_repository.dart';

class GetPackages {
  final PackageRepository repository;

  GetPackages(this.repository);

  Future<List<PackageEntity>> call() async {
    return repository.getPackages();
  }
}
