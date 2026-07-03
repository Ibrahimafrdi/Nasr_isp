import 'package:nasr_isp/features/auth/data/models/user_model.dart';

abstract class UserManagementRepository {
  Future<List<UserModel>> getUsers();
  Future<void> createUser(String email, String password, String name, String role);
  Future<void> updateUserRole(String uid, String role);
  Future<void> toggleUserStatus(String uid, bool isActive);
}
