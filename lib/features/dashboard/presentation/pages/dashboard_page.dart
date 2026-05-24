import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/theme/app_typography.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:nasr_isp/shared/widgets/alert_panel.dart';
import 'package:nasr_isp/shared/widgets/kpi_card.dart';
import 'package:nasr_isp/shared/widgets/premium_data_table.dart';
import 'package:nasr_isp/shared/widgets/quick_action_card.dart';

/// Role-aware Dashboard Page
///
/// Content changes based on user role:
/// - Admin: Full dashboard with all modules
/// - Employee: Limited dashboard without admin modules
///
/// NOTE: Layout (sidebar/topbar) is provided by AppShell
class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const LoadDashboardEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: Text('Not authenticated'));
        }

        final user = authState.user;
        final isAdmin = user.role.isAdmin;

        return BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DashboardError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.errorRed,
                    ),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<DashboardBloc>().add(
                          const LoadDashboardEvent(),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Message
                  Text(
                    'Good ${_getGreeting()}, ${user.name} 👋',
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    isAdmin ? 'Admin Dashboard' : 'Employee Dashboard',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.mediumGray,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),

                  // Alerts Section (Admin Only)
                  if (isAdmin) ...[
                    Column(
                      children: [
                        AlertPanel(
                          type: AlertType.warning,
                          title: '5 Customers Expiring Soon',
                          message:
                              'Customer packages will expire in the next 7 days',
                          icon: Icons.warning_amber,
                          actionLabel: 'Review',
                          onActionTap: () => context.go(RoutePaths.customers),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        AlertPanel(
                          type: AlertType.error,
                          title: 'Payment Overdue',
                          message: '12 customers have unpaid invoices',
                          icon: Icons.error_outline,
                          actionLabel: 'Collect',
                          onActionTap: () => context.go(RoutePaths.payments),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xxl),
                  ],

                  // KPI Cards
                  Text(
                    isAdmin ? 'Financial Overview' : 'My Performance',
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _buildKPICards(isAdmin),
                  SizedBox(height: AppSpacing.xxl),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _buildQuickActions(context, isAdmin),
                  SizedBox(height: AppSpacing.xxl),

                  // Admin-only sections
                  if (isAdmin) ...[
                    Text(
                      'Expiring Contracts (Next 7 Days)',
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _buildExpiringTable(),
                    SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Recent Payments',
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _buildRecentPaymentsTable(),
                    SizedBox(height: AppSpacing.xxl),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning';
    } else if (hour < 17) {
      return 'Afternoon';
    } else {
      return 'Evening';
    }
  }

  Widget _buildKPICards(bool isAdmin) {
    return GridView.count(
      crossAxisCount: isAdmin ? 3 : 2,
      crossAxisSpacing: AppSpacing.lg,
      mainAxisSpacing: AppSpacing.lg,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isAdmin ? 1.8 : 1.5, // Admin vs employee ratios
      children: [
        KPICard(
          title: 'Total Customers',
          value: '1,245',
          subtitle: 'Active accounts',
          trend: '+12.5%',
          isTrendPositive: true,
          icon: Icons.people,
          gradient: AppColors.blueGradient,
        ),
        KPICard(
          title: 'Active Subscribers',
          value: '980',
          subtitle: 'Current active',
          trend: '+8.2%',
          isTrendPositive: true,
          icon: Icons.check_circle,
          gradient: AppColors.greenGradient,
        ),
        if (isAdmin)
          KPICard(
            title: 'Monthly Revenue',
            value: 'EGP 450K',
            subtitle: 'Current month',
            trend: '+15.3%',
            isTrendPositive: true,
            icon: Icons.trending_up,
            gradient: AppColors.purpleGradient,
          ),
        if (isAdmin)
          KPICard(
            title: 'Total Expenses',
            value: 'EGP 125K',
            subtitle: 'Month to date',
            trend: '+5.1%',
            isTrendPositive: false,
            icon: Icons.receipt,
            gradient: AppColors.orangeGradient,
          ),
        if (isAdmin)
          KPICard(
            title: 'Net Profit',
            value: 'EGP 325K',
            subtitle: 'This month',
            trend: '+22.4%',
            isTrendPositive: true,
            icon: Icons.attach_money,
            gradient: AppColors.purpleGradient,
          ),
        if (isAdmin)
          KPICard(
            title: 'Pending Payments',
            value: 'EGP 85K',
            subtitle: '24 invoices',
            trend: '-3.2%',
            isTrendPositive: true,
            icon: Icons.schedule,
            gradient: AppColors.redGradient,
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isAdmin) {
    final actionCount = isAdmin ? 5 : 3;
    return GridView.count(
      crossAxisCount: actionCount,
      crossAxisSpacing: AppSpacing.lg,
      mainAxisSpacing: AppSpacing.lg,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: [
        QuickActionCard(
          icon: Icons.person,
          label: 'Add Customer',
          iconColor: AppColors.primaryBlue,
          onTap: () => context.go(RoutePaths.addCustomer),
        ),
        QuickActionCard(
          icon: Icons.payments,
          label: 'Record Payment',
          iconColor: AppColors.successGreen,
          onTap: () => context.go(RoutePaths.payments),
        ),
        if (isAdmin)
          QuickActionCard(
            icon: Icons.receipt_long,
            label: 'Add Expense',
            iconColor: AppColors.warningOrange,
            onTap: () => context.go(RoutePaths.expenses),
          ),
        if (isAdmin)
          QuickActionCard(
            icon: Icons.inventory_2,
            label: 'Add Inventory',
            iconColor: AppColors.blueAccent,
            onTap: () => context.go(RoutePaths.inventory),
          ),
        if (isAdmin)
          QuickActionCard(
            icon: Icons.assessment,
            label: 'Generate Report',
            iconColor: AppColors.primaryBlue,
            onTap: () => context.go(RoutePaths.reports),
          ),
      ],
    );
  }

  Widget _buildExpiringTable() {
    return PremiumDataTable(
      columns: [
        PremiumDataColumn(label: 'Customer Name'),
        PremiumDataColumn(label: 'Package'),
        PremiumDataColumn(label: 'Expiry Date'),
        PremiumDataColumn(label: 'Days Left'),
        PremiumDataColumn(label: 'Status', width: 0.15),
        PremiumDataColumn(label: 'Action', width: 0.15),
      ],
      rows: [
        PremiumDataRow(
          cells: [
            'Ahmed Hassan',
            'Premium 10Mbps',
            '2024-05-25',
            '4 days',
            'Expiring',
            'Renew',
          ],
        ),
        PremiumDataRow(
          cells: [
            'Fatima Mohamed',
            'Business 50Mbps',
            '2024-05-26',
            '5 days',
            'Expiring',
            'Renew',
          ],
        ),
        PremiumDataRow(
          cells: [
            'Mohammed Ali',
            'Standard 5Mbps',
            '2024-05-27',
            '6 days',
            'Expiring',
            'Renew',
          ],
        ),
        PremiumDataRow(
          cells: [
            'Sara Ibrahim',
            'Premium 10Mbps',
            '2024-05-28',
            '7 days',
            'Expiring',
            'Renew',
          ],
        ),
      ],
    );
  }

  Widget _buildRecentPaymentsTable() {
    return PremiumDataTable(
      columns: [
        PremiumDataColumn(label: 'Customer'),
        PremiumDataColumn(label: 'Method'),
        PremiumDataColumn(label: 'Amount'),
        PremiumDataColumn(label: 'Status', width: 0.15),
        PremiumDataColumn(label: 'Date'),
      ],
      rows: [
        PremiumDataRow(
          cells: [
            'Ahmed Hassan',
            'Bank Transfer',
            'EGP 500',
            'Completed',
            '2024-05-21',
          ],
        ),
        PremiumDataRow(
          cells: [
            'Fatima Mohamed',
            'Cash',
            'EGP 1,000',
            'Completed',
            '2024-05-21',
          ],
        ),
        PremiumDataRow(
          cells: ['Mohammed Ali', 'Card', 'EGP 250', 'Pending', '2024-05-21'],
        ),
      ],
    );
  }
}
