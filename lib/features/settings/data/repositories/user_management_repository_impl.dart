import 'package:nasr_isp/features/auth/data/models/user_model.dart';
import 'package:nasr_isp/features/settings/data/datasources/user_management_remote_data_source.dart';
import 'package:nasr_isp/features/settings/domain/repositories/user_management_repository.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  final UserManagementRemoteDataSource remoteDataSource;

  UserManagementRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<UserModel>> getUsers() async {
    return await remoteDataSource.getUsers();
  }

  @override
  Future<void> createUser(
    String email,
    String password,
    String name,
    String role,
  ) async {
    await remoteDataSource.createUser(email, password, name, role);
  }

  @override
  Future<void> updateUserRole(String uid, String role) async {
    await remoteDataSource.updateUserRole(uid, role);
  }

  @override
  Future<void> toggleUserStatus(String uid, bool isActive) async {
    await remoteDataSource.toggleUserStatus(uid, isActive);
  }
}
