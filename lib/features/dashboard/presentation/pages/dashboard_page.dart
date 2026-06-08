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
import 'package:nasr_isp/shared/widgets/status_badge.dart';

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
  bool _showExpiringAlert = true;
  bool _showOverdueAlert = true;

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
                  if (isAdmin && (_showExpiringAlert || _showOverdueAlert)) ...[
                    Column(
                      children: [
                        if (_showExpiringAlert) ...[
                          AlertPanel(
                            type: AlertType.warning,
                            title: '5 Customers Expiring Soon',
                            message:
                                'Customer packages will expire in the next 7 days',
                            icon: Icons.warning_amber,
                            actionLabel: 'Review',
                            onActionTap: () => context.go(RoutePaths.customers),
                            onDismiss: () {
                              setState(() {
                                _showExpiringAlert = false;
                              });
                            },
                          ),
                          if (_showOverdueAlert)
                            SizedBox(height: AppSpacing.lg),
                        ],
                        if (_showOverdueAlert)
                          AlertPanel(
                            type: AlertType.error,
                            title: 'Payment Overdue',
                            message: '12 customers have unpaid invoices',
                            icon: Icons.error_outline,
                            actionLabel: 'Collect',
                            onActionTap: () => context.go(RoutePaths.payments),
                            onDismiss: () {
                              setState(() {
                                _showOverdueAlert = false;
                              });
                            },
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
      childAspectRatio: isAdmin ? 1.75 : 1.45, // Admin vs employee ratios
      children: [
        KPICard(
          title: 'Total Customers',
          value: '1,245',
          subtitle: 'Active accounts',
          trend: '+12.5%',
          isTrendPositive: true,
          icon: Icons.people,
          gradient: AppColors.blueGradient,
          sparklineData: const [
            2.0,
            3.0,
            5.0,
            4.0,
            7.0,
            6.0,
            8.0,
            9.0,
            8.0,
            10.0,
          ],
        ),
        KPICard(
          title: 'Active Subscribers',
          value: '980',
          subtitle: 'Current active',
          trend: '+8.2%',
          isTrendPositive: true,
          icon: Icons.check_circle,
          gradient: AppColors.greenGradient,
          sparklineData: const [
            4.0,
            5.0,
            4.0,
            6.0,
            5.0,
            7.0,
            8.0,
            7.0,
            9.0,
            9.0,
          ],
        ),
        if (isAdmin)
          KPICard(
            title: 'Monthly Revenue',
            value: '450K PKR',
            subtitle: 'Current month',
            trend: '+15.3%',
            isTrendPositive: true,
            icon: Icons.trending_up,
            gradient: AppColors.purpleGradient,
            sparklineData: const [
              5.0,
              4.0,
              6.0,
              7.0,
              6.0,
              8.0,
              7.0,
              9.0,
              10.0,
              11.0,
            ],
          ),
        if (isAdmin)
          KPICard(
            title: 'Total Expenses',
            value: '125K PKR',
            subtitle: 'Month to date',
            trend: '+5.1%',
            isTrendPositive: false,
            icon: Icons.receipt,
            gradient: AppColors.orangeGradient,
            sparklineData: const [
              8.0,
              7.0,
              6.0,
              5.0,
              4.0,
              3.0,
              4.0,
              5.0,
              4.0,
              3.0,
            ],
          ),
        if (isAdmin)
          KPICard(
            title: 'Net Profit',
            value: '325K PKR',
            subtitle: 'This month',
            trend: '+22.4%',
            isTrendPositive: true,
            icon: Icons.attach_money,
            gradient: AppColors.purpleGradient,
            sparklineData: const [
              2.0,
              3.0,
              2.0,
              4.0,
              5.0,
              6.0,
              7.0,
              6.0,
              8.0,
              10.0,
            ],
          ),
        if (isAdmin)
          KPICard(
            title: 'Pending Payments',
            value: '85K PKR',
            subtitle: '24 invoices',
            trend: '-3.2%',
            isTrendPositive: true,
            icon: Icons.schedule,
            gradient: AppColors.redGradient,
            sparklineData: const [
              10.0,
              9.0,
              8.0,
              9.0,
              7.0,
              6.0,
              5.0,
              6.0,
              4.0,
              2.0,
            ],
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isAdmin) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = isAdmin ? 6 : 5;
        if (constraints.maxWidth < 600) {
          columns = 2;
        } else if (constraints.maxWidth < 1100) {
          columns = 3;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.lg,
          mainAxisSpacing: AppSpacing.lg,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio:
              1.15, // Adjusted to fit gradients and description beautifully
          children: [
            QuickActionCard(
              icon: Icons.person_add,
              label: 'Add Customer',
              description: 'Provision new internet user',
              gradient: AppColors.blueGradient,
              onTap: () => context.go(RoutePaths.addCustomer),
            ),
            QuickActionCard(
              icon: Icons.payments,
              label: 'Collect Payment',
              description: 'Record subscriber dues cash',
              gradient: AppColors.greenGradient,
              onTap: () => context.go(RoutePaths.payments),
            ),
            // QuickActionCard(
            //   icon: Icons.receipt_long,
            //   label: 'Create Invoice',
            //   description: 'Generate monthly service bills',
            //   gradient: AppColors.purpleGradient,
            //   onTap: () => context.go(RoutePaths.payments),
            // ),
            QuickActionCard(
              icon: Icons.engineering,
              label: 'Register Installation',
              description: 'Provision fiber connection line',
              gradient: AppColors.orangeGradient,
              onTap: () => context.go(RoutePaths.installations),
            ),
            QuickActionCard(
              icon: Icons.inventory_2,
              label: 'Add Inventory Item',
              description: 'Stock ONU devices & cabling',
              gradient: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
              onTap: () => context.go(RoutePaths.inventory),
            ),
            if (isAdmin)
              QuickActionCard(
                icon: Icons.assessment,
                label: 'View Reports',
                description: 'Analyze net sales & costs',
                gradient: AppColors.redGradient,
                onTap: () => context.go(RoutePaths.reports),
              ),
          ],
        );
      },
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
            const Text(
              'Ahmed Hassan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            const Text(
              'Premium 10Mbps',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Text('2024-05-25'),
            const Text(
              '4 days',
              style: TextStyle(
                color: AppColors.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            const StatusBadge(
              status: StatusType.expiring,
              label: 'ExpiringSoon',
            ),
            TextButton(
              onPressed: () => context.go(RoutePaths.customers),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Renew',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        PremiumDataRow(
          cells: [
            const Text(
              'Fatima Mohamed',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            const Text(
              'Business 50Mbps',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Text('2024-05-26'),
            const Text(
              '5 days',
              style: TextStyle(
                color: AppColors.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            const StatusBadge(
              status: StatusType.expiring,
              label: 'ExpiringSoon',
            ),
            TextButton(
              onPressed: () => context.go(RoutePaths.customers),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Renew',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        PremiumDataRow(
          cells: [
            const Text(
              'Mohammed Ali',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            const Text(
              'Standard 5Mbps',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Text('2024-05-27'),
            const Text(
              '6 days',
              style: TextStyle(
                color: AppColors.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            const StatusBadge(
              status: StatusType.expiring,
              label: 'ExpiringSoon',
            ),
            TextButton(
              onPressed: () => context.go(RoutePaths.customers),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Renew',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        PremiumDataRow(
          cells: [
            const Text(
              'Sara Ibrahim',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            const Text(
              'Premium 10Mbps',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Text('2024-05-28'),
            const Text(
              '7 days',
              style: TextStyle(
                color: AppColors.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            const StatusBadge(
              status: StatusType.expiring,
              label: 'ExpiringSoon',
            ),
            TextButton(
              onPressed: () => context.go(RoutePaths.customers),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Renew',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
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
            const Text(
              'Ahmed Hassan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            const Text('Bank Transfer'),
            const Text(
              '500 PKR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.successGreen,
              ),
            ),
            const StatusBadge(status: StatusType.active, label: 'Completed'),
            const Text('2024-05-21'),
          ],
        ),
        PremiumDataRow(
          cells: [
            const Text(
              'Fatima Mohamed',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            const Text('Cash'),
            const Text(
              '1,000 PKR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.successGreen,
              ),
            ),
            const StatusBadge(status: StatusType.active, label: 'Completed'),
            const Text('2024-05-21'),
          ],
        ),
        PremiumDataRow(
          cells: [
            const Text(
              'Mohammed Ali',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            const Text('Card'),
            const Text(
              '250 PKR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.warningOrange,
              ),
            ),
            const StatusBadge(status: StatusType.pending, label: 'Pending'),
            const Text('2024-05-21'),
          ],
        ),
      ],
    );
  }
}
