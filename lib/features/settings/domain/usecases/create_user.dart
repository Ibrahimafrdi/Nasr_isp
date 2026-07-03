import 'package:nasr_isp/features/settings/domain/repositories/user_management_repository.dart';

class CreateUser {
  final UserManagementRepository repository;

  CreateUser(this.repository);

  Future<void> call({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    return repository.createUser(email, password, name, role);
  }
}
