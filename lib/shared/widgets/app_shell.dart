import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';


class AppShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const AppShell({Key? key, required this.child, required this.currentRoute})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          // While authentication state is resolving, show a loader.
          // Navigation is handled globally by the router redirects.
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authState.user;

        final bool childIsScaffold = child is Scaffold;

        String resolveTitle(String route) {
          if (route.startsWith(RoutePaths.customers)) return 'Customers';
          if (route.startsWith(RoutePaths.payments)) return 'Payments';
          if (route.startsWith(RoutePaths.expenses)) return 'Expenses';
          if (route.startsWith(RoutePaths.reports)) return 'Reports';
          if (route.startsWith(RoutePaths.employees)) return 'Employees';
          if (route.startsWith(RoutePaths.installations))
            return 'Installations';
          if (route.startsWith(RoutePaths.inventory)) return 'Inventory';
          if (route.startsWith(RoutePaths.khataa)) return 'Khataa Ledger';
          if (route.startsWith(RoutePaths.settings)) return 'Settings';
          return 'Dashboard';
        }

        return Scaffold(
          backgroundColor: AppTheme.veryLightGray,
          body: LayoutBuilder(
            builder: (context, constraints) {
              // Mobile layout
              if (constraints.maxWidth < 768) {
                if (childIsScaffold) {
                  // Let the child scaffold render itself on small screens
                  return child;
                }

                return Column(
                  children: [
                    DashboardTopBar(
                      title: resolveTitle(currentRoute),
                      currentUser: user,
                    ),
                    Expanded(child: SingleChildScrollView(child: child)),
                  ],
                );
              }

              // Desktop/Tablet layout
              if (childIsScaffold) {
                // If the page provides its own scaffold (with topbar/sidebar), render it directly
                return child;
              }

              return Row(
                children: [
                  // Sidebar
                  DashboardSidebar(
                    currentUser: user,
                    currentRoute: currentRoute,
                    onLogout: () {
                      context.read<AuthBloc>().add(const LogoutEvent());
                      context.go(RoutePaths.login);
                    },
                  ),
                  // Main content area
                  Expanded(
                    child: Column(
                      children: [
                        DashboardTopBar(
                          title: resolveTitle(currentRoute),
                          currentUser: user,
                        ),
                        Expanded(child: SingleChildScrollView(child: child)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
