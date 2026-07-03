import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/repositories/installation_repository.dart';

class UpdateInstallation {
  final InstallationRepository repository;

  UpdateInstallation(this.repository);

  Future<void> call(InstallationEntity installation) async {
    return repository.updateInstallation(installation);
  }
}
