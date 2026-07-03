import 'package:nasr_isp/features/packages/domain/repositories/package_repository.dart';

class DeletePackage {
  final PackageRepository repository;

  DeletePackage(this.repository);

  Future<void> call(String id) => repository.deletePackage(id);
}
