import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const AppShell({super.key, required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authState.user;

        String resolveTitle(String route) {
          if (route.startsWith(RoutePaths.customers)) return 'Customers';
          if (route.startsWith(RoutePaths.packages)) return 'Packages';
          if (route.startsWith(RoutePaths.payments)) return 'Payments';
          if (route.startsWith(RoutePaths.expenses)) return 'Expenses';
          if (route.startsWith(RoutePaths.employees)) return 'Employees';
          if (route.startsWith(RoutePaths.installations))
            return 'Installations';
          if (route.startsWith(RoutePaths.inventory)) return 'Inventory';
          if (route.startsWith(RoutePaths.suppliers)) return 'Suppliers';
          if (route.startsWith(RoutePaths.reports)) return 'Reports';
          if (route.startsWith(RoutePaths.settings)) return 'Settings';
          return 'Dashboard';
        }

        String? resolveSection(String route) {
          if (route.startsWith(RoutePaths.customers) ||
              route.startsWith(RoutePaths.installations) ||
              route.startsWith(RoutePaths.packages) ||
              route.startsWith(RoutePaths.inventory) ||
              route.startsWith(RoutePaths.suppliers)) {
            return 'Operations';
          }
          if (route.startsWith(RoutePaths.payments) ||
              route.startsWith(RoutePaths.expenses) ||
              route.startsWith(RoutePaths.reports)) {
            return 'Finance';
          }
          if (route.startsWith(RoutePaths.employees) ||
              route.startsWith(RoutePaths.settings)) {
            return 'Admin';
          }
          return null;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final deviceType = Responsive.deviceTypeForWidth(
              constraints.maxWidth,
            );

            void handleLogout() {
              context.read<AuthBloc>().add(const LogoutEvent());
              context.go(RoutePaths.login);
            }

            if (deviceType != DeviceType.desktop) {
              // ── Mobile & Tablet: AppBar + Drawer ─────────────────────────
              return Scaffold(
                backgroundColor: AppTheme.veryLightGray,
                appBar: DashboardTopBar(
                  title: resolveTitle(currentRoute),
                  section: resolveSection(currentRoute),
                  currentUser: user,
                ),
                drawer: Drawer(
                  width: 248,
                  backgroundColor: const Color(0xFF101827),
                  child: DashboardSidebar(
                    currentUser: user,
                    currentRoute: currentRoute,
                    forceCollapsed: false,
                    showCollapseToggle: false,
                    onLogout: handleLogout,
                  ),
                ),
                body: SafeArea(child: child),
              );
            } else {
              // ── Desktop: dark sidebar + slim context bar ─────────────────
              return Scaffold(
                backgroundColor: AppTheme.veryLightGray,
                body: Row(
                  children: [
                    DashboardSidebar(
                      currentUser: user,
                      currentRoute: currentRoute,
                      onLogout: handleLogout,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          DashboardTopBar(
                            title: resolveTitle(currentRoute),
                            section: resolveSection(currentRoute),
                            currentUser: user,
                          ),
                          Expanded(child: child),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }
}
