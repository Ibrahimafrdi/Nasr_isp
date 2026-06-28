import 'package:nasr_isp/features/packages/data/datasources/package_remote_data_source.dart';
import 'package:nasr_isp/features/packages/data/models/package_model.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/domain/repositories/package_repository.dart';

class PackageRepositoryImpl implements PackageRepository {
  final PackageRemoteDataSource remoteDataSource;

  PackageRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> addPackage(PackageEntity package) async {
    final model = PackageModel(
      id: package.id,
      name: package.name,
      speed: package.speed,
      price: package.price,
      description: package.description,
      createdAt: package.createdAt,
    );
    await remoteDataSource.addPackage(model);
  }

  @override
  Future<List<PackageEntity>> getPackages() async {
    return await remoteDataSource.getPackages();
  }
}
