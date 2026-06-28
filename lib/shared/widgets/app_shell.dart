import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/responsive/breakpoints.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
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
          if (route.startsWith(RoutePaths.installations)) return 'Installations';
          if (route.startsWith(RoutePaths.inventory)) return 'Inventory';
          if (route.startsWith(RoutePaths.khataa)) return 'Khataa Ledger';
          if (route.startsWith(RoutePaths.settings)) return 'Settings';
          return 'Dashboard';
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < Breakpoints.mobile;
            final isTablet =
                width >= Breakpoints.mobile && width < Breakpoints.tablet;

            void handleLogout() {
              context.read<AuthBloc>().add(const LogoutEvent());
              context.go(RoutePaths.login);
            }

            if (isMobile) {
              // ── Mobile: AppBar + Drawer ──────────────────────────────────
              return Scaffold(
                backgroundColor: AppTheme.veryLightGray,
                appBar: DashboardTopBar(
                  title: resolveTitle(currentRoute),
                  currentUser: user,
                ),
                drawer: Drawer(
                  child: DashboardSidebar(
                    currentUser: user,
                    currentRoute: currentRoute,
                    forceCollapsed: false,
                    onLogout: handleLogout,
                  ),
                ),
                body: SafeArea(child: child),
              );
            } else if (isTablet) {
              // ── Tablet: Collapsed sidebar + TopBar ───────────────────────
              return Scaffold(
                backgroundColor: AppTheme.veryLightGray,
                body: Row(
                  children: [
                    DashboardSidebar(
                      currentUser: user,
                      currentRoute: currentRoute,
                      forceCollapsed: true,
                      onLogout: handleLogout,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          DashboardTopBar(
                            title: resolveTitle(currentRoute),
                            currentUser: user,
                          ),
                          Expanded(child: child),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // ── Desktop: Full expanded sidebar ───────────────────────────
              return Scaffold(
                backgroundColor: AppTheme.veryLightGray,
                body: Row(
                  children: [
                    DashboardSidebar(
                      currentUser: user,
                      currentRoute: currentRoute,
                      forceCollapsed: false,
                      onLogout: handleLogout,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          DashboardTopBar(
                            title: resolveTitle(currentRoute),
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
