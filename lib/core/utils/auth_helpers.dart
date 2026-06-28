import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/shared/models/models.dart';

/// Authorization helpers for role-based access control
class AuthHelpers {
  // Admin-only route paths
  static const List<String> _adminOnlyRoutes = [
    RoutePaths.expenses,
    RoutePaths.employees,
    RoutePaths.settings,
    RoutePaths.inventory,
    RoutePaths.khataa,
  ];

  /// Check if user is an admin
  static bool isAdmin(UserModel user) => user.isAdmin;

  /// Check if user is an employee
  static bool isEmployee(UserModel user) => user.isEmployee;

  /// Check if user has access to admin-only routes
  static bool canAccessAdminRoutes(UserModel user) => user.isAdmin;

  /// Check if user can edit packages (admin only)
  static bool canEditPackages(UserModel user) => user.isAdmin;

  /// Check if user can view financial information (admin only)
  static bool canViewFinancials(UserModel user) => user.isAdmin;

  /// Check if user has access to a specific route
  static bool hasRouteAccess(UserModel user, String routePath) {
    if (_adminOnlyRoutes.contains(routePath)) {
      return isAdmin(user);
    }
    // All authenticated users can access other routes
    return true;
  }

  /// Check if route is admin-only
  static bool isAdminOnlyRoute(String routePath) {
    return _adminOnlyRoutes.contains(routePath);
  }

  /// Get the appropriate dashboard route based on user role
  static String getDashboardRoute(UserModel user) => RoutePaths.dashboard;

  /// Get user role display name
  static String getRoleDisplayName(String role) {
    return role.toLowerCase() == 'admin' ? 'Administrator' : 'Employee';
  }
}
