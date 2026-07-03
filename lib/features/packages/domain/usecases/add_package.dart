import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/domain/repositories/package_repository.dart';

class AddPackage {
  final PackageRepository repository;

  AddPackage(this.repository);

  /// Returns the Firestore-generated document id of the new package.
  Future<String> call(PackageEntity package) =>
      repository.addPackage(package);
}
