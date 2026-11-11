import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/features/auth/data/models/user_model.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nasr_isp/features/auth/domain/repositories/auth_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

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
  final String? message; // e.g. "Session expired, please log in again."
  const LogoutEvent({this.message});
  @override
  List<Object?> get props => [message];
}

class AuthCheckEvent extends AuthEvent {
  const AuthCheckEvent();
}

// ── States ────────────────────────────────────────────────────────────────────

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

// ── Bloc ──────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  /// How long an admin stays logged in after signing in.
  static const Duration sessionDuration = Duration(hours: 1);

  Timer? _sessionTimer;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<AuthCheckEvent>(_onAuthCheck);
  }

  // ── Session expiry ──────────────────────────────────────────────────────────

  bool _isSessionExpired() {
    final lastLogin =
        FirebaseAuth.instance.currentUser?.metadata.lastSignInTime;
    if (lastLogin == null) return false;
    return DateTime.now().difference(lastLogin) > sessionDuration;
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isSessionExpired()) {
        add(
          const LogoutEvent(message: 'Session expired. Please log in again.'),
        );
      }
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  @override
  Future<void> close() {
    _stopSessionTimer();
    return super.close();
  }

  // ── Handlers ────────────────────────────────────────────────────────────────

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
      _startSessionTimer();
    } on Exception catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(message: message));
    } catch (e) {
      emit(AuthError(message: 'Unexpected error: ${e.toString()}'));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    _stopSessionTimer();
    await _authRepository.logout();
    emit(AuthUnauthenticated(message: event.message));
  }

  Future<void> _onAuthCheck(
    AuthCheckEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      if (_isSessionExpired()) {
        await _authRepository.logout();
        emit(
          const AuthUnauthenticated(
            message: 'Session expired. Please log in again.',
          ),
        );
        return;
      }

      emit(AuthAuthenticated(user: user));
      _startSessionTimer();
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }
}
