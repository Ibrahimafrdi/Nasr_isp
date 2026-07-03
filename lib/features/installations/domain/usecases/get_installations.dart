import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/repositories/installation_repository.dart';

class GetInstallations {
  final InstallationRepository repository;

  GetInstallations(this.repository);

  Future<List<InstallationEntity>> call({
    String? status,
    String? connectionType,
    String? employeeId,
    String? searchQuery,
  }) async {
    return repository.getInstallations(
      status: status,
      connectionType: connectionType,
      employeeId: employeeId,
      searchQuery: searchQuery,
    );
  }
}
