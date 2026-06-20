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
import 'package:nasr_isp/shared/widgets/premium_kpi_card.dart';
import 'package:nasr_isp/shared/widgets/metric_card_widget.dart';
import 'package:nasr_isp/shared/widgets/activity_timeline_widget.dart';
import 'package:nasr_isp/shared/widgets/professional_action_button.dart';
import 'package:nasr_isp/shared/widgets/premium_data_table.dart';
import 'package:nasr_isp/shared/widgets/status_chip_widget.dart';

/// Premium Dashboard Page - Professional SaaS-style ISP Management Dashboard
///
/// Features:
/// - Clean white background with professional cards
/// - Hierarchical layout: KPIs → Metrics → Actions → Timeline → Data
/// - Responsive design for desktop, laptop, tablet
/// - Role-based content (Admin vs Employee)
/// - Modern minimal design with blue theme
///
/// Layout:
/// 1. Welcome message and greeting
/// 2. Alert panels (admin only)
/// 3. Primary KPI cards (4 main metrics)
/// 4. Secondary metrics section (pending/expiring)
/// 5. Quick actions panel
/// 6. Recent activity timeline
/// 7. Data tables (expiring contracts, recent payments)
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
                  // ===== WELCOME SECTION =====
                  _buildWelcomeSection(user),
                  SizedBox(height: AppSpacing.xxl),

                  // ===== ALERTS SECTION (Admin Only) =====
                  if (isAdmin && (_showExpiringAlert || _showOverdueAlert))
                    _buildAlertsSection(context),
                  if (isAdmin && (_showExpiringAlert || _showOverdueAlert))
                    SizedBox(height: AppSpacing.xxl),

                  // ===== PRIMARY KPI CARDS (Main Metrics) =====
                  _buildSectionHeader('Key Metrics', isAdmin),
                  SizedBox(height: AppSpacing.lg),
                  _buildPrimaryKPICards(isAdmin),
                  SizedBox(height: AppSpacing.xxl),

                  // ===== SECONDARY METRICS SECTION =====
                  _buildSectionHeader('Quick Overview', isAdmin),
                  SizedBox(height: AppSpacing.lg),
                  _buildSecondaryMetrics(isAdmin),
                  SizedBox(height: AppSpacing.xxl),

                  // ===== QUICK ACTIONS SECTION =====
                  _buildSectionHeader('Quick Actions', isAdmin),
                  SizedBox(height: AppSpacing.lg),
                  _buildQuickActionsPanel(context, isAdmin),
                  SizedBox(height: AppSpacing.xxl),

                  // ===== RECENT ACTIVITY TIMELINE =====
                  _buildSectionHeader('Recent Activity', isAdmin),
                  SizedBox(height: AppSpacing.lg),
                  _buildActivityTimeline(),
                  SizedBox(height: AppSpacing.xxl),

                  // ===== DATA TABLES (Admin Only) =====
                  if (isAdmin) ...[
                    _buildSectionHeader(
                      'Expiring Contracts (Next 7 Days)',
                      isAdmin,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _buildExpiringContractsTable(),
                    SizedBox(height: AppSpacing.xxl),
                    _buildSectionHeader('Recent Payments', isAdmin),
                    SizedBox(height: AppSpacing.lg),
                    _buildRecentPaymentsTable(),
                    SizedBox(height: AppSpacing.xxxl),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Welcome section with greeting and subtitle
  Widget _buildWelcomeSection(dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good ${_getGreeting()}, ${user.name} 👋',
          style: AppTypography.headingLarge.copyWith(
            color: AppColors.black,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          'Welcome back to your ISP management dashboard',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.mediumGray,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Alerts section with dismissible alert panels
  Widget _buildAlertsSection(BuildContext context) {
    return Column(
      children: [
        if (_showExpiringAlert) ...[
          AlertPanel(
            type: AlertType.warning,
            title: '5 Customers Expiring Soon',
            message:
                'Customer packages will expire in the next 7 days. Review and renew before service interruption.',
            icon: Icons.warning_amber,
            actionLabel: 'Review',
            onActionTap: () => context.go(RoutePaths.customers),
            onDismiss: () {
              setState(() => _showExpiringAlert = false);
            },
          ),
          if (_showOverdueAlert) SizedBox(height: AppSpacing.lg),
        ],
        if (_showOverdueAlert)
          AlertPanel(
            type: AlertType.error,
            title: 'Payments Overdue',
            message: '12 customers have unpaid invoices totaling 185K PKR.',
            icon: Icons.error_outline,
            actionLabel: 'Collect Now',
            onActionTap: () => context.go(RoutePaths.payments),
            onDismiss: () {
              setState(() => _showOverdueAlert = false);
            },
          ),
      ],
    );
  }

  /// Section header widget for consistent styling
  Widget _buildSectionHeader(String title, bool isAdmin) {
    return Text(
      title,
      style: AppTypography.headingMedium.copyWith(
        color: AppColors.black,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    );
  }

  /// Primary KPI cards - Main 4 metrics with minimal white design
  Widget _buildPrimaryKPICards(bool isAdmin) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive column count
        int columns = 4;
        if (constraints.maxWidth < 900) {
          columns = 2;
        } else if (constraints.maxWidth < 1200) {
          columns = 3;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.lg,
          mainAxisSpacing: AppSpacing.lg,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,
          children: [
            PremiumKPICard(
              title: 'Total Customers',
              value: '1,245',
              subtitle: 'Active accounts',
              trend: '+12.5%',
              isTrendPositive: true,
              icon: Icons.people,
              accentColor: AppColors.primaryBlue,
            ),
            PremiumKPICard(
              title: 'Active Subscribers',
              value: '980',
              subtitle: 'Currently active',
              trend: '+8.2%',
              isTrendPositive: true,
              icon: Icons.check_circle,
              accentColor: AppColors.successGreen,
            ),
            if (isAdmin)
              PremiumKPICard(
                title: 'Monthly Revenue',
                value: '450K',
                subtitle: 'PKR this month',
                trend: '+15.3%',
                isTrendPositive: true,
                icon: Icons.trending_up,
                accentColor: AppColors.primaryBlue,
              ),
            if (isAdmin)
              PremiumKPICard(
                title: 'Net Profit',
                value: '325K',
                subtitle: 'After expenses',
                trend: '+22.4%',
                isTrendPositive: true,
                icon: Icons.attach_money,
                accentColor: AppColors.successGreen,
              ),
            if (!isAdmin) ...[
              PremiumKPICard(
                title: 'Assigned Customers',
                value: '48',
                subtitle: 'Under your care',
                trend: '+2.3%',
                isTrendPositive: true,
                icon: Icons.group,
                accentColor: AppColors.primaryBlue,
              ),
              PremiumKPICard(
                title: 'Service Requests',
                value: '12',
                subtitle: 'Pending attention',
                trend: '-5.1%',
                isTrendPositive: true,
                icon: Icons.support_agent,
                accentColor: AppColors.warningOrange,
              ),
            ],
          ],
        );
      },
    );
  }

  /// Secondary metrics - Quick overview cards
  Widget _buildSecondaryMetrics(bool isAdmin) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;
        if (constraints.maxWidth < 900) {
          columns = 2;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.lg,
          mainAxisSpacing: AppSpacing.lg,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.65,
          children: [
            if (isAdmin)
              MetricCardWidget(
                label: 'Pending Payments',
                value: '85K PKR',
                icon: Icons.schedule,
                accentColor: AppColors.warningOrange,
                description: '24 invoices awaiting',
              ),
            if (isAdmin)
              MetricCardWidget(
                label: 'Total Expenses',
                value: '125K PKR',
                icon: Icons.receipt,
                accentColor: AppColors.errorRed,
                description: 'Month to date',
              ),
            MetricCardWidget(
              label: 'Expiring Soon',
              value: '5',
              icon: Icons.alarm,
              accentColor: AppColors.warningOrange,
              description: 'Next 7 days',
            ),
            MetricCardWidget(
              label: 'Support Tickets',
              value: '8',
              icon: Icons.help,
              accentColor: AppColors.primaryBlue,
              description: 'Open tickets',
            ),
          ],
        );
      },
    );
  }

  /// Quick actions panel with professional buttons
  Widget _buildQuickActionsPanel(BuildContext context, bool isAdmin) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = isAdmin ? 6 : 4;
        if (constraints.maxWidth < 600) {
          columns = 2;
        } else if (constraints.maxWidth < 1000) {
          columns = 3;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.lg,
          mainAxisSpacing: AppSpacing.lg,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          children: [
            ProfessionalActionButton(
              icon: Icons.person_add,
              label: 'Add Customer',
              description: 'New subscriber',
              accentColor: AppColors.primaryBlue,
              onTap: () => context.go(RoutePaths.addCustomer),
            ),
            ProfessionalActionButton(
              icon: Icons.payments,
              label: 'Collect Payment',
              description: 'Record payment',
              accentColor: AppColors.successGreen,
              onTap: () => context.go(RoutePaths.payments),
            ),
            ProfessionalActionButton(
              icon: Icons.engineering,
              label: 'New Installation',
              description: 'Fiber connection',
              accentColor: AppColors.warningOrange,
              onTap: () => context.go(RoutePaths.installations),
            ),
            ProfessionalActionButton(
              icon: Icons.inventory_2,
              label: 'Add Inventory',
              description: 'Stock items',
              accentColor: const Color(0xFF06B6D4),
              onTap: () => context.go(RoutePaths.inventory),
            ),
            if (isAdmin)
              ProfessionalActionButton(
                icon: Icons.assessment,
                label: 'View Reports',
                description: 'Analytics',
                accentColor: AppColors.primaryBlue,
                onTap: () => context.go(RoutePaths.reports),
              ),
            if (isAdmin)
              ProfessionalActionButton(
                icon: Icons.receipt_long,
                label: 'Create Invoice',
                description: 'Generate bill',
                accentColor: AppColors.errorRed,
                onTap: () => context.go(RoutePaths.payments),
              ),
          ],
        );
      },
    );
  }

  /// Recent activity timeline
  Widget _buildActivityTimeline() {
    final activities = [
      ActivityTimelineItem(
        title: 'New Customer Registered',
        description: 'Ahmed Hassan signed up for Premium 10Mbps package',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        icon: Icons.person_add,
        color: AppColors.primaryBlue,
        badge: 'Customer',
      ),
      ActivityTimelineItem(
        title: 'Payment Received',
        description: 'Fatima Mohamed paid 1,000 PKR via bank transfer',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        icon: Icons.check_circle,
        color: AppColors.successGreen,
        badge: 'Payment',
      ),
      ActivityTimelineItem(
        title: 'Installation Completed',
        description:
            'Fiber connection setup for Mohammed Ali completed successfully',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        icon: Icons.done_all,
        color: AppColors.successGreen,
        badge: 'Installation',
      ),
      ActivityTimelineItem(
        title: 'Contract Expiring',
        description: 'Sara Ibrahim\'s contract expires in 4 days',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        icon: Icons.warning,
        color: AppColors.warningOrange,
        badge: 'Alert',
      ),
    ];

    return ActivityTimelineWidget(
      items: activities,
      title: 'Recent Activity',
      onViewMore: () {
        // TODO: Navigate to activity log page
      },
    );
  }

  /// Expiring contracts table with professional styling
  Widget _buildExpiringContractsTable() {
    return PremiumDataTable(
      columns: [
        PremiumDataColumn(label: 'Customer', width: 0.25),
        PremiumDataColumn(label: 'Package', width: 0.2),
        PremiumDataColumn(label: 'Expiry Date', width: 0.2),
        PremiumDataColumn(label: 'Days Left', width: 0.15),
        PremiumDataColumn(label: 'Status', width: 0.15),
        PremiumDataColumn(label: 'Action', width: 0.15),
      ],
      rows: [
        PremiumDataRow(
          cells: [
            const Text(
              'Ahmed Hassan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const Text('Premium 10Mbps'),
            const Text('May 25, 2024'),
            const Text(
              '4 days',
              style: TextStyle(
                color: AppColors.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            StatusChipWidget(
              type: StatusChipType.expiringSoon,
              label: 'Expiring',
              showIcon: true,
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
              ),
              child: const Text('Renew'),
            ),
          ],
        ),
        PremiumDataRow(
          cells: [
            const Text(
              'Fatima Mohamed',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const Text('Business 50Mbps'),
            const Text('May 26, 2024'),
            const Text(
              '5 days',
              style: TextStyle(
                color: AppColors.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            StatusChipWidget(
              type: StatusChipType.expiringSoon,
              label: 'Expiring',
              showIcon: true,
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
              ),
              child: const Text('Renew'),
            ),
          ],
        ),
        PremiumDataRow(
          cells: [
            const Text(
              'Mohammed Ali',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const Text('Standard 5Mbps'),
            const Text('May 27, 2024'),
            const Text(
              '6 days',
              style: TextStyle(
                color: AppColors.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            StatusChipWidget(
              type: StatusChipType.expiringSoon,
              label: 'Expiring',
              showIcon: true,
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
              ),
              child: const Text('Renew'),
            ),
          ],
        ),
      ],
    );
  }

  /// Recent payments table with professional styling
  Widget _buildRecentPaymentsTable() {
    return PremiumDataTable(
      columns: [
        PremiumDataColumn(label: 'Customer', width: 0.25),
        PremiumDataColumn(label: 'Method', width: 0.2),
        PremiumDataColumn(label: 'Amount', width: 0.2),
        PremiumDataColumn(label: 'Status', width: 0.15),
        PremiumDataColumn(label: 'Date', width: 0.2),
      ],
      rows: [
        PremiumDataRow(
          cells: [
            const Text(
              'Ahmed Hassan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const Text('Bank Transfer'),
            const Text(
              '500 PKR',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.successGreen,
              ),
            ),
            StatusChipWidget(
              type: StatusChipType.completed,
              label: 'Completed',
              showIcon: true,
            ),
            const Text('May 21, 2024'),
          ],
        ),
        PremiumDataRow(
          cells: [
            const Text(
              'Fatima Mohamed',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const Text('Cash'),
            const Text(
              '1,000 PKR',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.successGreen,
              ),
            ),
            StatusChipWidget(
              type: StatusChipType.completed,
              label: 'Completed',
              showIcon: true,
            ),
            const Text('May 21, 2024'),
          ],
        ),
        PremiumDataRow(
          cells: [
            const Text(
              'Mohammed Ali',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const Text('Card'),
            const Text(
              '250 PKR',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.warningOrange,
              ),
            ),
            StatusChipWidget(
              type: StatusChipType.pending,
              label: 'Pending',
              showIcon: true,
            ),
            const Text('May 21, 2024'),
          ],
        ),
      ],
    );
  }

  /// Get greeting based on current hour
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
}
