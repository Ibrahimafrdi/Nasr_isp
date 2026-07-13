import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/features/auth/data/models/user_model.dart';
import 'package:nasr_isp/features/settings/domain/usecases/create_user.dart';
import 'package:nasr_isp/features/settings/domain/usecases/get_users.dart';
import 'package:nasr_isp/features/settings/domain/usecases/toggle_user_status.dart';
import 'package:nasr_isp/features/settings/domain/usecases/update_user_role.dart';

// User Management Events
abstract class UserManagementEvent extends Equatable {
  const UserManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsersEvent extends UserManagementEvent {
  const LoadUsersEvent();
}

class CreateUserEvent extends UserManagementEvent {
  final String email;
  final String password;
  final String name;
  final String role;

  const CreateUserEvent({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, name, role];
}

class UpdateUserRoleEvent extends UserManagementEvent {
  final String uid;
  final String role;

  const UpdateUserRoleEvent({required this.uid, required this.role});

  @override
  List<Object?> get props => [uid, role];
}

class ToggleUserStatusEvent extends UserManagementEvent {
  final String uid;
  final bool isActive;

  const ToggleUserStatusEvent({required this.uid, required this.isActive});

  @override
  List<Object?> get props => [uid, isActive];
}

// User Management States
abstract class UserManagementState extends Equatable {
  const UserManagementState();

  @override
  List<Object?> get props => [];
}

class UserManagementInitial extends UserManagementState {
  const UserManagementInitial();
}

class UserManagementLoading extends UserManagementState {
  const UserManagementLoading();
}

class UserManagementLoaded extends UserManagementState {
  final List<UserModel> users;

  const UserManagementLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class UserManagementSaving extends UserManagementState {
  const UserManagementSaving();
}

class UserManagementSuccess extends UserManagementState {
  final String message;

  const UserManagementSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Emitted after a user is created. Creating a user via the Firebase Client
/// SDK signs the admin out as a side effect (see
/// UserManagementRemoteDataSourceImpl.createUser) — the admin's session is no
/// longer valid, so the page should force a clean re-login with a clear
/// explanation rather than let a confusing failure surface later.
class UserManagementUserCreatedNeedsReauth extends UserManagementState {
  final String message;

  const UserManagementUserCreatedNeedsReauth(this.message);

  @override
  List<Object?> get props => [message];
}

class UserManagementError extends UserManagementState {
  final String message;

  const UserManagementError({required this.message});

  @override
  List<Object?> get props => [message];
}

// User Management BLoC
class UserManagementBloc
    extends Bloc<UserManagementEvent, UserManagementState> {
  final GetUsers getUsers;
  final CreateUser createUser;
  final UpdateUserRole updateUserRole;
  final ToggleUserStatus toggleUserStatus;

  UserManagementBloc({
    required this.getUsers,
    required this.createUser,
    required this.updateUserRole,
    required this.toggleUserStatus,
  }) : super(const UserManagementInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<CreateUserEvent>(_onCreateUser);
    on<UpdateUserRoleEvent>(_onUpdateUserRole);
    on<ToggleUserStatusEvent>(_onToggleUserStatus);
  }

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(const UserManagementLoading());
    try {
      final users = await getUsers();
      emit(UserManagementLoaded(users));
    } catch (e) {
      emit(UserManagementError(message: 'Failed to load users: $e'));
    }
  }

  Future<void> _onCreateUser(
    CreateUserEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(const UserManagementSaving());
    try {
      await createUser(
        email: event.email,
        password: event.password,
        name: event.name,
        role: event.role,
      );
      // Don't try to reload the users list here — the admin's own session
      // was just invalidated by the sign-out side effect, so that read
      // would likely fail anyway. Let the page handle a clean re-login.
      emit(UserManagementUserCreatedNeedsReauth(
        '"${event.name}" was created successfully. For security reasons, you need to log back in.',
      ));
    } catch (e) {
      emit(UserManagementError(message: 'Failed to create user: $e'));
      // Keep existing users if we can
      try {
        final users = await getUsers();
        emit(UserManagementLoaded(users));
      } catch (_) {}
    }
  }

  Future<void> _onUpdateUserRole(
    UpdateUserRoleEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(const UserManagementSaving());
    try {
      await updateUserRole(uid: event.uid, role: event.role);
      emit(const UserManagementSuccess('User role updated successfully.'));
      final users = await getUsers();
      emit(UserManagementLoaded(users));
    } catch (e) {
      emit(UserManagementError(message: 'Failed to update user role: $e'));
      try {
        final users = await getUsers();
        emit(UserManagementLoaded(users));
      } catch (_) {}
    }
  }

  Future<void> _onToggleUserStatus(
    ToggleUserStatusEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(const UserManagementSaving());
    try {
      await toggleUserStatus(uid: event.uid, isActive: event.isActive);
      emit(UserManagementSuccess(
        event.isActive ? 'User activated successfully.' : 'User deactivated successfully.',
      ));
      final users = await getUsers();
      emit(UserManagementLoaded(users));
    } catch (e) {
      emit(UserManagementError(message: 'Failed to update user status: $e'));
      try {
        final users = await getUsers();
        emit(UserManagementLoaded(users));
      } catch (_) {}
    }
  }
}
