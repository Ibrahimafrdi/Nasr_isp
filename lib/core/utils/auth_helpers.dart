import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/shared/models/models.dart';

/// Authorization helpers for role-based access control
class AuthHelpers {
  /// Check if user is an admin
  static bool isAdmin(UserModel user) {
    return user.role.isAdmin;
  }

  /// Check if user is an employee
  static bool isEmployee(UserModel user) {
    return !user.role.isAdmin;
  }

  /// Check if user has access to admin-only routes
  static bool canAccessAdminRoutes(UserModel user) {
    return user.role.isAdmin;
  }

  /// Check if user can access employee routes
  static bool canAccessEmployeeRoutes(UserModel user) {
    return true; // All authenticated users can access
  }

  /// Check if user has access to a specific route
  static bool hasRouteAccess(UserModel user, String routePath) {
    // Admin-only routes
    const adminOnlyRoutes = [
      RoutePaths.expenses,
      RoutePaths.reports,
      RoutePaths.employees,
    ];

    if (adminOnlyRoutes.contains(routePath)) {
      return isAdmin(user);
    }

    // All authenticated users can access other routes
    return true;
  }

  /// Get the appropriate dashboard route based on user role
  static String getDashboardRoute(UserModel user) {
    return RoutePaths.dashboard;
  }

  /// Get user role display name
  static String getRoleDisplayName(UserRole role) {
    return role.isAdmin ? 'Administrator' : 'Employee';
  }

  /// Check if route is admin-only
  static bool isAdminOnlyRoute(String routePath) {
    const adminOnlyRoutes = [
      RoutePaths.expenses,
      RoutePaths.reports,
      RoutePaths.employees,
    ];
    return adminOnlyRoutes.contains(routePath);
  }
}
