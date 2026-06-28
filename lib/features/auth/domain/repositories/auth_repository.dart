import 'package:nasr_isp/features/auth/data/models/user_model.dart';

/// Contract that the domain layer depends on.
/// Concrete implementation lives in the data layer.
abstract class AuthRepository {
  /// Authenticates with [email] / [password].
  /// Returns the authenticated [UserModel] on success.
  /// Throws a [String] human-readable error message on failure.
  Future<UserModel> login({required String email, required String password});

  /// Signs out the current user.
  Future<void> logout();

  /// Returns the currently authenticated [UserModel], or null if not signed in.
  Future<UserModel?> getCurrentUser();
}
