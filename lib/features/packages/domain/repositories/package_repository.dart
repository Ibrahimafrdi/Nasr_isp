import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';

abstract class PackageRepository {
  Future<List<PackageEntity>> getPackages({
    ConnectionType? filterByType,
    bool? activeOnly,
  });

  Future<PackageEntity> getPackageById(String id);

  Future<String> addPackage(PackageEntity package);

  Future<void> updatePackage(PackageEntity package);

  Future<void> deletePackage(String id);
}
