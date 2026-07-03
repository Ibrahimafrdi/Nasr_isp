import 'package:nasr_isp/features/auth/data/models/user_model.dart';
import 'package:nasr_isp/features/settings/domain/repositories/user_management_repository.dart';

class GetUsers {
  final UserManagementRepository repository;

  GetUsers(this.repository);

  Future<List<UserModel>> call() async {
    return repository.getUsers();
  }
}
