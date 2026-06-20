import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:nasr_isp/shared/widgets/alert_panel.dart';
import 'package:nasr_isp/shared/widgets/kpi_card.dart';
import 'package:nasr_isp/shared/widgets/premium_data_table.dart';
import 'package:nasr_isp/shared/widgets/quick_action_card.dart';
import 'package:nasr_isp/shared/widgets/status_badge.dart';
import 'package:nasr_isp/shared/widgets/responsive_table.dart';
import 'package:nasr_isp/shared/widgets/mobile_dashboard_card.dart';
import 'package:nasr_isp/shared/widgets/analytics_card.dart';
import 'package:nasr_isp/shared/widgets/activity_timeline_widget.dart';

/// Production-level SaaS Dashboard Page (Frontend-only, static placeholder data)
///
/// NOTE: Data is currently hardcoded for UI/UX finalization. Once approved,
/// values here will be swapped to read from `DashboardLoaded` state
/// (state.stats, state.expiringCustomers, state.recentPayments) without
/// any layout changes required.
///
/// Supports Desktop Web, Tablet, and Mobile responsive experiences.
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
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              );
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
                    Text(
                      state.message,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== HEADER =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good ${_getGreeting()}, ${user.name} 👋',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAdmin
                                  ? 'Admin Dashboard Overview'
                                  : 'Employee Performance Metrics',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.darkGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ===== ALERTS (Admin Only) =====
                  if (isAdmin && (_showExpiringAlert || _showOverdueAlert)) ...[
                    Column(
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
                          if (_showOverdueAlert) const SizedBox(height: 16),
                        ],
                        if (_showOverdueAlert)
                          AlertPanel(
                            type: AlertType.error,
                            title: 'Payments Overdue',
                            message:
                                '12 customers have unpaid invoices totaling 185K PKR.',
                            icon: Icons.error_outline,
                            actionLabel: 'Collect Now',
                            onActionTap: () => context.go(RoutePaths.payments),
                            onDismiss: () {
                              setState(() => _showOverdueAlert = false);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ===== KPI CARDS =====
                  Text(
                    isAdmin ? 'Financial & Service Overview' : 'Key Metrics',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildKPICards(isAdmin),
                  const SizedBox(height: 32),

                  // ===== QUICK ACTIONS =====
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(context, isAdmin),
                  const SizedBox(height: 32),

                  // ===== ANALYTICS (Admin Only) =====
                  if (isAdmin) ...[
                    Text(
                      'Analytics & Performance Statistics',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const AnalyticsSection(),
                    const SizedBox(height: 32),
                  ],

                  // ===== RECENT ACTIVITY =====
                  Text(
                    'Recent Activity',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityTimeline(),
                  const SizedBox(height: 32),

                  // ===== DATA TABLES (Admin Only) =====
                  if (isAdmin) ...[
                    Text(
                      'Expiring Contracts (Next 7 Days)',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildExpiringTable(),
                    const SizedBox(height: 32),

                    Text(
                      'Recent Payments',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecentPaymentsTable(),
                    const SizedBox(height: 24),
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

  // ===== KPI CARDS (static placeholder data) =====
  Widget _buildKPICards(bool isAdmin) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;
        if (constraints.maxWidth >= 1200) {
          columns = isAdmin ? 3 : 2;
        } else if (constraints.maxWidth >= 650) {
          columns = 2;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.lg,
          mainAxisSpacing: AppSpacing.lg,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isAdmin ? 1.6 : 1.45,
          children: [
            KPICard(
              title: 'Total Customers',
              value: '1,245',
              subtitle: 'Active accounts',
              trend: '+12.5%',
              isTrendPositive: true,
              icon: Icons.people,
              gradient: AppColors.blueGradient,
              sparklineData: const [2, 3, 5, 4, 7, 6, 8, 9, 8, 10],
            ),
            KPICard(
              title: 'Active Subscribers',
              value: '980',
              subtitle: 'Currently active',
              trend: '+8.2%',
              isTrendPositive: true,
              icon: Icons.check_circle,
              gradient: AppColors.greenGradient,
              sparklineData: const [4, 5, 4, 6, 5, 7, 8, 7, 9, 9],
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
                sparklineData: const [5, 4, 6, 7, 6, 8, 7, 9, 10, 11],
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
                sparklineData: const [8, 7, 6, 5, 4, 3, 4, 5, 4, 3],
              ),
            if (isAdmin)
              KPICard(
                title: 'Net Profit',
                value: '325K PKR',
                subtitle: 'After expenses',
                trend: '+22.4%',
                isTrendPositive: true,
                icon: Icons.attach_money,
                gradient: AppColors.purpleGradient,
                sparklineData: const [2, 3, 2, 4, 5, 6, 7, 6, 8, 10],
              ),
            if (isAdmin)
              KPICard(
                title: 'Pending Payments',
                value: '85K PKR',
                subtitle: '24 invoices awaiting',
                trend: '-3.2%',
                isTrendPositive: true,
                icon: Icons.schedule,
                gradient: AppColors.redGradient,
                sparklineData: const [10, 9, 8, 9, 7, 6, 5, 6, 4, 2],
              ),
            if (!isAdmin) ...[
              KPICard(
                title: 'Assigned Customers',
                value: '48',
                subtitle: 'Under your care',
                trend: '+2.3%',
                isTrendPositive: true,
                icon: Icons.group,
                gradient: AppColors.blueGradient,
                sparklineData: const [3, 4, 3, 5, 4, 6, 5, 7, 6, 8],
              ),
              KPICard(
                title: 'Expiring Soon',
                value: '5',
                subtitle: 'Next 7 days',
                trend: '-5.1%',
                isTrendPositive: true,
                icon: Icons.alarm,
                gradient: AppColors.orangeGradient,
                sparklineData: const [6, 5, 6, 4, 5, 3, 4, 3, 2, 5],
              ),
            ],
          ],
        );
      },
    );
  }

  // ===== QUICK ACTIONS (Tickets & Reports removed) =====
  Widget _buildQuickActions(BuildContext context, bool isAdmin) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = isAdmin ? 4 : 4;
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
          childAspectRatio: 1.15,
          children: [
            QuickActionCard(
              icon: Icons.person_add,
              label: 'Add Customer',
              description: 'Provision new subscriber',
              gradient: AppColors.blueGradient,
              onTap: () => context.go(RoutePaths.addCustomer),
            ),
            QuickActionCard(
              icon: Icons.payments,
              label: 'Collect Payment',
              description: 'Record subscriber dues',
              gradient: AppColors.greenGradient,
              onTap: () => context.go(RoutePaths.payments),
            ),
            QuickActionCard(
              icon: Icons.engineering,
              label: 'Register Installation',
              description: 'Fiber connection line',
              gradient: AppColors.orangeGradient,
              onTap: () => context.go(RoutePaths.installations),
            ),
            QuickActionCard(
              icon: Icons.inventory_2,
              label: 'Add Inventory Item',
              description: 'Stock ONU and cabling',
              gradient: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
              onTap: () => context.go(RoutePaths.inventory),
            ),
          ],
        );
      },
    );
  }

  // ===== ACTIVITY TIMELINE (static placeholder data) =====
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
        description: "Sara Ibrahim's contract expires in 4 days",
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
        // TODO: Navigate to full activity log page once built
      },
    );
  }

  // ===== EXPIRING CONTRACTS TABLE (static placeholder data) =====
  Widget _buildExpiringTable() {
    final expiringRows = [
      {
        'name': 'Ahmed Hassan',
        'package': 'Premium 10Mbps',
        'date': 'May 25, 2024',
        'days': 4,
      },
      {
        'name': 'Fatima Mohamed',
        'package': 'Business 50Mbps',
        'date': 'May 26, 2024',
        'days': 5,
      },
      {
        'name': 'Mohammed Ali',
        'package': 'Standard 5Mbps',
        'date': 'May 27, 2024',
        'days': 6,
      },
    ];

    return ResponsiveTable(
      columns: [
        PremiumDataColumn(label: 'Customer Name'),
        PremiumDataColumn(label: 'Package'),
        PremiumDataColumn(label: 'Expiry Date'),
        PremiumDataColumn(label: 'Days Left'),
        PremiumDataColumn(label: 'Status', width: 0.15),
        PremiumDataColumn(label: 'Action', width: 0.15),
      ],
      rows: expiringRows.map((row) {
        final daysLeft = row['days'] as int;
        return PremiumDataRow(
          cells: [
            Text(
              row['name'] as String,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            Text(
              row['package'] as String,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            Text(row['date'] as String),
            Text(
              '$daysLeft days',
              style: GoogleFonts.inter(
                color: daysLeft <= 7
                    ? AppColors.errorRed
                    : AppColors.warningOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const StatusBadge(status: StatusType.expiring, label: 'Expiring'),
            TextButton(
              onPressed: () => context.go(RoutePaths.customers),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Renew',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      }).toList(),
      mobileItemBuilder: (context, index) {
        final row = expiringRows[index];
        final daysLeft = row['days'] as int;

        return MobileDashboardCard(
          title: row['name'] as String,
          subtitle: row['package'] as String,
          statusBadge: const StatusBadge(
            status: StatusType.expiring,
            label: 'Expiring Soon',
          ),
          details: {
            'Expiry Date': row['date'] as String,
            'Days Left': '$daysLeft days',
          },
          actionButton: TextButton(
            onPressed: () => context.go(RoutePaths.customers),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryBlue.withOpacity(0.08),
              foregroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Renew Package',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  // ===== RECENT PAYMENTS TABLE (static placeholder data) =====
  Widget _buildRecentPaymentsTable() {
    final paymentRows = [
      {
        'name': 'Ahmed Hassan',
        'method': 'Bank Transfer',
        'amount': '500 PKR',
        'status': StatusType.completed,
        'date': 'May 21, 2024',
      },
      {
        'name': 'Fatima Mohamed',
        'method': 'Cash',
        'amount': '1,000 PKR',
        'status': StatusType.completed,
        'date': 'May 21, 2024',
      },
      {
        'name': 'Mohammed Ali',
        'method': 'Card',
        'amount': '250 PKR',
        'status': StatusType.pending,
        'date': 'May 21, 2024',
      },
    ];

    return ResponsiveTable(
      columns: [
        PremiumDataColumn(label: 'Customer'),
        PremiumDataColumn(label: 'Method'),
        PremiumDataColumn(label: 'Amount'),
        PremiumDataColumn(label: 'Status', width: 0.15),
        PremiumDataColumn(label: 'Date'),
      ],
      rows: paymentRows.map((row) {
        final status = row['status'] as StatusType;
        return PremiumDataRow(
          cells: [
            Text(
              row['name'] as String,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            Text(row['method'] as String),
            Text(
              row['amount'] as String,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: status == StatusType.completed
                    ? AppColors.successGreen
                    : AppColors.warningOrange,
              ),
            ),
            StatusBadge(status: status),
            Text(row['date'] as String),
          ],
        );
      }).toList(),
      mobileItemBuilder: (context, index) {
        final row = paymentRows[index];
        final status = row['status'] as StatusType;

        return MobileDashboardCard(
          title: row['name'] as String,
          subtitle: row['method'] as String,
          statusBadge: StatusBadge(status: status),
          details: {
            'Amount': row['amount'] as String,
            'Date': row['date'] as String,
          },
        );
      },
    );
  }
}
