import 'package:nasr_isp/features/installations/domain/repositories/installation_repository.dart';

class DeleteInstallation {
  final InstallationRepository repository;

  DeleteInstallation(this.repository);

  Future<void> call(String id) async {
    return repository.deleteInstallation(id);
  }
}
