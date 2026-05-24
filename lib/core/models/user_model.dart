class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' or 'employee'
  final String phone;
  final String? profileImage;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    this.profileImage,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isEmployee => role.toLowerCase() == 'employee';
}

class AuthState {
  final bool isAuthenticated;
  final UserModel? user;
  final String? error;
  final bool isLoading;

  AuthState({
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserModel? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
