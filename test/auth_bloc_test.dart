import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/auth/data/models/user_model.dart';
import 'package:nasr_isp/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<UserModel> login({required String email, required String password}) async {
    if (email == 'admin@nasr.com' && password == 'admin123') {
      return const UserModel(
        id: 'admin_uid',
        email: 'admin@nasr.com',
        role: 'admin',
        name: 'Admin User',
        phone: '1234567890',
      );
    }
    throw Exception('Invalid email or password');
  }

  @override
  Future<void> logout() async {}

  @override
  Future<UserModel?> getCurrentUser() async => null;
}

void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;
    late FakeAuthRepository fakeAuthRepository;

    setUp(() {
      fakeAuthRepository = FakeAuthRepository();
      authBloc = AuthBloc(authRepository: fakeAuthRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    test('successful login emits AuthLoading and AuthAuthenticated with correct UserRole', () async {
      final expectedStates = [
        const AuthLoading(),
        isA<AuthAuthenticated>().having(
          (state) => state.user.role,
          'role',
          'admin',
        ),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const LoginEvent(
        email: 'admin@nasr.com',
        password: 'admin123',
      ));
    });

    test('failed login emits AuthLoading and AuthError', () async {
      final expectedStates = [
        const AuthLoading(),
        isA<AuthError>().having(
          (state) => state.message,
          'message',
          'Invalid email or password',
        ),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const LoginEvent(
        email: 'admin@nasr.com',
        password: 'wrongpassword',
      ));
    });
  });
}
