import 'package:nasr_isp/features/installations/data/datasources/installation_remote_data_source.dart';
import 'package:nasr_isp/features/installations/data/models/installation_model.dart';
import 'package:nasr_isp/features/installations/data/models/installation_item_used_model.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/repositories/installation_repository.dart';

class InstallationRepositoryImpl implements InstallationRepository {
  final InstallationRemoteDataSource remoteDataSource;

  InstallationRepositoryImpl({required this.remoteDataSource});

  InstallationModel _toModel(InstallationEntity e) {
    return InstallationModel(
      id: e.id,
      customerId: e.customerId,
      customerName: e.customerName,
      connectionType: e.connectionType,
      installationDate: e.installationDate,
      assignedEmployeeId: e.assignedEmployeeId,
      assignedEmployeeName: e.assignedEmployeeName,
      installationCost: e.installationCost,
      status: e.status,
      remarks: e.remarks,
      itemsUsed: e.itemsUsed?.map((item) => InstallationItemUsedModel(
            inventoryItemId: item.inventoryItemId,
            itemName: item.itemName,
            quantity: item.quantity,
            costPriceAtTime: item.costPriceAtTime,
          )).toList(),
      createdAt: e.createdAt,
      completedAt: e.completedAt,
    );
  }

  @override
  Future<void> createInstallation(InstallationEntity installation) async {
    await remoteDataSource.addInstallation(_toModel(installation));
  }

  @override
  Future<List<InstallationEntity>> getInstallations({
    String? status,
    String? connectionType,
    String? employeeId,
    String? searchQuery,
  }) async {
    return await remoteDataSource.getInstallations(
      status: status,
      connectionType: connectionType,
      employeeId: employeeId,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<List<InstallationEntity>> getInstallationsByCustomer(String customerId) async {
    return await remoteDataSource.getInstallationsByCustomer(customerId);
  }

  @override
  Future<void> updateInstallation(InstallationEntity installation) async {
    await remoteDataSource.updateInstallation(_toModel(installation));
  }

  @override
  Future<void> deleteInstallation(String id) async {
    await remoteDataSource.deleteInstallation(id);
  }
}
