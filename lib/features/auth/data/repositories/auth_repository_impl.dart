import 'package:firebase_auth/firebase_auth.dart';
import 'package:nasr_isp/features/auth/data/datasources/firebase_auth_service.dart';
import 'package:nasr_isp/features/auth/data/models/user_model.dart';
import 'package:nasr_isp/features/auth/domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository].
/// Delegates all Firebase calls to [FirebaseAuthService] and maps
/// low-level exceptions into human-readable error strings.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthService _authService;

  AuthRepositoryImpl({required FirebaseAuthService authService})
      : _authService = authService;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final firebaseUser = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      final userModel = await _authService.fetchUserProfile(firebaseUser.uid);
      if (userModel == null) {
        // Sign out so Firebase doesn't consider the session valid.
        await _authService.signOut();
        throw Exception('User profile not found. Contact admin.');
      }

      if (!userModel.isActive) {
        await _authService.signOut();
        throw Exception('This account is inactive. Contact admin.');
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    }
    // Other exceptions propagate as-is.
  }

  @override
  Future<void> logout() => _authService.signOut();

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) return null;

      await _authService.reloadCurrentUser();

      return _authService.fetchUserProfile(firebaseUser.uid);
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact admin.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Login failed. Please try again.';
    }
  }
}
