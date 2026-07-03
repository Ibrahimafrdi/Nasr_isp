import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';

abstract class InstallationRepository {
  Future<void> createInstallation(InstallationEntity installation);
  Future<void> updateInstallation(InstallationEntity installation);
  Future<List<InstallationEntity>> getInstallations({
    String? status,
    String? connectionType,
    String? employeeId,
    String? searchQuery,
  });
  Future<List<InstallationEntity>> getInstallationsByCustomer(String customerId);
  Future<void> deleteInstallation(String id);
}
