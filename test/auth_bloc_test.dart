import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;

    setUp(() {
      authBloc = AuthBloc();
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
          UserRole.admin,
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
