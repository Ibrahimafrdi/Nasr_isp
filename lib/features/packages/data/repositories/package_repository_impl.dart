import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/packages/data/datasources/package_remote_data_source.dart';
import 'package:nasr_isp/features/packages/data/models/package_model.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/domain/repositories/package_repository.dart';

class PackageRepositoryImpl implements PackageRepository {
  final PackageRemoteDataSource remoteDataSource;

  PackageRepositoryImpl({required this.remoteDataSource});

  // ── Entity → Model mapping ─────────────────────────────────────────────────

  PackageModel _toModel(PackageEntity e) => PackageModel(
        id: e.id,
        name: e.name,
        speedMbps: e.speedMbps,
        price: e.price,
        costPrice: e.costPrice,
        connectionType: e.connectionType,
        description: e.description,
        isActive: e.isActive,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );

  // ── Repository implementation ──────────────────────────────────────────────

  @override
  Future<List<PackageEntity>> getPackages({
    ConnectionType? filterByType,
    bool? activeOnly,
  }) =>
      remoteDataSource.getPackages(
        filterByType: filterByType,
        activeOnly: activeOnly,
      );

  @override
  Future<PackageEntity> getPackageById(String id) =>
      remoteDataSource.getPackageById(id);

  @override
  Future<String> addPackage(PackageEntity package) =>
      remoteDataSource.addPackage(_toModel(package));

  @override
  Future<void> updatePackage(PackageEntity package) =>
      remoteDataSource.updatePackage(_toModel(package));

  @override
  Future<void> deletePackage(String id) => remoteDataSource.deletePackage(id);
}
