import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';

abstract class PackageRepository {
  Future<void> addPackage(PackageEntity package);
  Future<List<PackageEntity>> getPackages();
}
