import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/utils/auth_helpers.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/auth/presentation/pages/login_page.dart';
import 'package:nasr_isp/features/customers/presentation/pages/add_customer_page.dart';
import 'package:nasr_isp/features/customers/presentation/pages/customer_details_page.dart';
import 'package:nasr_isp/features/customers/presentation/pages/customers_page.dart';
import 'package:nasr_isp/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:nasr_isp/features/employees/presentation/pages/employees_page.dart';
import 'package:nasr_isp/features/expenses/presentation/pages/expenses_page.dart';
import 'package:nasr_isp/features/installations/presentation/pages/installations_page.dart';
import 'package:nasr_isp/features/payments/presentation/pages/payments_page.dart';
import 'package:nasr_isp/features/reports/presentation/pages/reports_page.dart';
import 'package:nasr_isp/features/settings/presentation/pages/settings_page.dart';
import 'package:nasr_isp/features/inventory/presentation/pages/inventory_page.dart';
import 'package:nasr_isp/features/khataa/presentation/pages/khataa_page.dart';
import 'package:nasr_isp/shared/widgets/app_shell.dart';

GoRouter createAppRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: RoutePaths.login,
    refreshListenable: GoRouterRefreshBloc(authBloc),
    redirect: _goRouterRedirect,
    routes: [
      // Login Route (public)
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      // Shell Routes (authenticated - wrapped with AppShell)
      ShellRoute(
        builder: (context, state, child) {
          // Extract current route for sidebar highlighting
          final location = state.matchedLocation;
          return AppShell(currentRoute: location, child: child);
        },
        routes: [
          // Dashboard
          GoRoute(
            path: RoutePaths.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          // Customers
          GoRoute(
            path: RoutePaths.customers,
            builder: (context, state) => const CustomersPage(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddCustomerPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return CustomerDetailsPage(customerId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return AddCustomerPage(customerId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Payments
          GoRoute(
            path: RoutePaths.payments,
            builder: (context, state) => const PaymentsPage(),
          ),
          // Expenses (admin-only)
          GoRoute(
            path: RoutePaths.expenses,
            builder: (context, state) => const ExpensesPage(),
            redirect: (context, state) {
              final authBloc = context.read<AuthBloc>();
              if (authBloc.state is AuthAuthenticated) {
                final user = (authBloc.state as AuthAuthenticated).user;
                if (!AuthHelpers.canAccessAdminRoutes(user)) {
                  return RoutePaths.dashboard;
                }
              }
              return null;
            },
          ),
          // Reports (admin-only)
          GoRoute(
            path: RoutePaths.reports,
            builder: (context, state) => const ReportsPage(),
            redirect: (context, state) {
              final authBloc = context.read<AuthBloc>();
              if (authBloc.state is AuthAuthenticated) {
                final user = (authBloc.state as AuthAuthenticated).user;
                if (!AuthHelpers.canAccessAdminRoutes(user)) {
                  return RoutePaths.dashboard;
                }
              }
              return null;
            },
          ),
          // Employees (admin-only)
          GoRoute(
            path: RoutePaths.employees,
            builder: (context, state) => const EmployeesPage(),
            redirect: (context, state) {
              final authBloc = context.read<AuthBloc>();
              if (authBloc.state is AuthAuthenticated) {
                final user = (authBloc.state as AuthAuthenticated).user;
                if (!AuthHelpers.canAccessAdminRoutes(user)) {
                  return RoutePaths.dashboard;
                }
              }
              return null;
            },
          ),
          // Installations
          GoRoute(
            path: RoutePaths.installations,
            builder: (context, state) => const InstallationsPage(),
          ),
          // Inventory
          GoRoute(
            path: RoutePaths.inventory,
            builder: (context, state) => const InventoryPage(),
          ),
          // Khataa
          GoRoute(
            path: RoutePaths.khataa,
            builder: (context, state) => const KhataaPage(),
          ),
          // Settings
          GoRoute(
            path: RoutePaths.settings,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
}

/// Simple ChangeNotifier that notifies the router when AuthBloc state changes
class GoRouterRefreshBloc extends ChangeNotifier {
  GoRouterRefreshBloc(this.bloc) {
    _sub = bloc.stream.listen((_) => notifyListeners());
  }

  final AuthBloc bloc;
  late final StreamSubscription _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Global redirect for authentication
String? _goRouterRedirect(BuildContext context, GoRouterState state) {
  final authBloc = context.read<AuthBloc>();
  final isLogin = state.matchedLocation == RoutePaths.login;
  final isAuthenticated = authBloc.state is AuthAuthenticated;

  // If not authenticated and not on login page, redirect to login
  if (!isAuthenticated && !isLogin) {
    return RoutePaths.login;
  }

  // If authenticated and on login page, redirect to dashboard
  if (isAuthenticated && isLogin) {
    return RoutePaths.dashboard;
  }

  // Otherwise, allow navigation
  return null;
}
