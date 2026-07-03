import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/repositories/installation_repository.dart';

class GetInstallationsByCustomer {
  final InstallationRepository repository;

  GetInstallationsByCustomer(this.repository);

  Future<List<InstallationEntity>> call(String customerId) async {
    return repository.getInstallationsByCustomer(customerId);
  }
}
