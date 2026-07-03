import 'package:nasr_isp/features/settings/domain/repositories/user_management_repository.dart';

class ToggleUserStatus {
  final UserManagementRepository repository;

  ToggleUserStatus(this.repository);

  Future<void> call({required String uid, required bool isActive}) async {
    return repository.toggleUserStatus(uid, isActive);
  }
}
