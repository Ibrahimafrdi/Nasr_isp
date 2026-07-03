import 'package:nasr_isp/features/settings/domain/repositories/user_management_repository.dart';

class UpdateUserRole {
  final UserManagementRepository repository;

  UpdateUserRole(this.repository);

  Future<void> call({required String uid, required String role}) async {
    return repository.updateUserRole(uid, role);
  }
}
