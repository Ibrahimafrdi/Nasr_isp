import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/shared/models/models.dart';

// Auth Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class AuthCheckEvent extends AuthEvent {
  const AuthCheckEvent();
}

// Auth States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  final String? message;

  const AuthUnauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Auth BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<AuthCheckEvent>(_onAuthCheck);
  }

  // Mock users for demo
  static final Map<String, Map<String, dynamic>> _mockUsers = {
    'admin@nasr.com': {
      'password': 'admin123',
      'name': 'Nasr Ullah',
      'phone': '+923001234567',
      'role': 'admin',
    },
    'employee@nasr.com': {
      'password': 'emp123',
      'name': 'Ahmed Ali',
      'phone': '+923009876543',
      'role': 'employee',
    },
  };

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(seconds: 1));

    try {
      final user = _mockUsers[event.email];
      if (user != null && user['password'] == event.password) {
        final roleString = user['role'] as String;
        final role = roleString == 'admin' ? UserRole.admin : UserRole.employee;

        final userModel = UserModel(
          id: event.email.split('@').first,
          name: user['name'] as String,
          email: event.email,
          phone: user['phone'] as String,
          role: role,
        );
        emit(AuthAuthenticated(user: userModel));
      } else {
        emit(const AuthError(message: 'Invalid email or password'));
      }
    } catch (e) {
      emit(AuthError(message: 'Login failed: ${e.toString()}'));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthUnauthenticated());
  }

  Future<void> _onAuthCheck(
    AuthCheckEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Check if user is logged in (from local storage, etc.)
    emit(const AuthUnauthenticated());
  }
}
