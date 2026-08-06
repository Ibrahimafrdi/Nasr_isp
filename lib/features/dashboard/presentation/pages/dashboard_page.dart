import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/widgets/alert_panel.dart';
import 'package:nasr_isp/shared/widgets/kpi_card.dart';
import 'package:nasr_isp/shared/widgets/premium_data_table.dart';
import 'package:nasr_isp/shared/widgets/quick_action_card.dart';
import 'package:nasr_isp/shared/widgets/status_badge.dart';
import 'package:nasr_isp/shared/widgets/responsive_table.dart';
import 'package:nasr_isp/shared/widgets/mobile_dashboard_card.dart';
import 'package:nasr_isp/shared/widgets/analytics_card.dart';
import 'package:nasr_isp/shared/widgets/activity_timeline_widget.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';

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

  Future<void> _onRefresh() async {
    final bloc = context.read<DashboardBloc>();
    bloc.add(const RefreshDashboardEvent());
    await bloc.stream.firstWhere(
      (s) => s is DashboardLoaded || s is DashboardError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: Text('Not authenticated'));
        }

        final user = authState.user;
        final isAdmin = user.isAdmin;

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

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                  if (isAdmin && state is DashboardLoaded) ...[
                    if (_showExpiringAlert &&
                        state.expiringCustomers.isNotEmpty)
                      AlertPanel(
                        type: AlertType.warning,
                        title:
                            '${state.stats.expiringsoon} Customers Expiring Soon',
                        message:
                            'Customer packages will expire in the next 7 days. Review and renew before service interruption.',
                        icon: Icons.warning_amber,
                        actionLabel: 'Review',
                        onActionTap: () => context.go(RoutePaths.customers),
                        onDismiss: () =>
                            setState(() => _showExpiringAlert = false),
                      ),
                    if (_showOverdueAlert &&
                        state.stats.pendingThisMonth > 0) ...[
                      if (_showExpiringAlert &&
                          state.expiringCustomers.isNotEmpty)
                        const SizedBox(height: 16),
                      // Routes to wherever the fix actually is: an unrenewed
                      // customer is renewed from the Customers page, while a
                      // part-paid charge is settled on the Payments ledger.
                      AlertPanel(
                        type: AlertType.error,
                        title: state.stats.expiredCustomersDueCount > 0
                            ? 'Renewals Outstanding'
                            : 'Balances Outstanding',
                        message: _pendingAlertMessage(state.stats),
                        icon: Icons.error_outline,
                        actionLabel: state.stats.expiredCustomersDueCount > 0
                            ? 'Renew Now'
                            : 'Collect Now',
                        onActionTap: () => context.go(
                          state.stats.expiredCustomersDueCount > 0
                              ? RoutePaths.customers
                              : RoutePaths.payments,
                        ),
                        onDismiss: () =>
                            setState(() => _showOverdueAlert = false),
                      ),
                    ],
                    if ((state.expiringCustomers.isNotEmpty ||
                            state.pendingPayments.isNotEmpty) &&
                        (_showExpiringAlert || _showOverdueAlert))
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
                  _buildKPICards(
                    isAdmin,
                    state is DashboardLoaded
                        ? state.stats
                        : const DashboardStatsModel(
                            totalCustomers: 0,
                            activeCustomers: 0,
                            expiredCustomers: 0,
                            expiringsoon: 0,
                            subscriberRunRateMargin: 0,
                            cashCollectedThisMonth: 0,
                            monthlyExpenses: 0,
                            netProfit: 0,
                            pendingPayments: 0,
                            pendingPaymentsCount: 0,
                            pendingInstallations: 0,
                            completedInstallations: 0,
                            monthlyInstallationRevenue: 0,
                            monthlyInstallationCost: 0,
                            monthlyInstallationProfit: 0,
                          ),
                  ),
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
                  if (isAdmin && state is DashboardLoaded) ...[
                    Text(
                      'Analytics & Performance Statistics',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnalyticsSection(
                      monthlyRevenue6: state.monthlyRevenue6,
                      customerGrowth6: state.customerGrowth6,
                      connectionTypeDist: state.connectionTypeDist,
                      paymentByMethod: state.paymentByMethod,
                    ),
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
                  _buildActivityTimeline(
                    state is DashboardLoaded ? state.recentPayments : [],
                  ),
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
                    _buildExpiringTable(
                      state is DashboardLoaded ? state.expiringCustomers : [],
                    ),
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
                    _buildRecentPaymentsTable(
                      state is DashboardLoaded ? state.recentPayments : [],
                    ),
                    const SizedBox(height: 24),

                    // ===== INSTALLATION COUNTS (Admin Only) =====
                    Text(
                      'Installation Overview',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInstallationOverview(
                      state is DashboardLoaded
                          ? state.stats.pendingInstallations
                          : 0,
                      state is DashboardLoaded
                          ? state.stats.completedInstallations
                          : 0,
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInstallationOverview(int pending, int completed) {
    final pendingCard = KPICard(
      title: 'Pending Installs',
      value: pending.toString(),
      subtitle: 'Awaiting & in-progress jobs',
      trend: null,
      isTrendPositive: false,
      icon: Icons.construction,
      gradient: AppColors.orangeGradient,
      sparklineData: [2, 1, 3, 2, 4, 3, 2, 3, 2, pending.toDouble() + 1],
      onTap: () => context.go(RoutePaths.installations),
    );
    final completedCard = KPICard(
      title: 'Completed Installs',
      value: completed.toString(),
      subtitle: 'Successfully provisioned lines',
      trend: null,
      isTrendPositive: true,
      icon: Icons.check_circle_outline,
      gradient: AppColors.greenGradient,
      sparklineData: [5, 6, 5, 7, 8, 7, 9, 8, 10, completed.toDouble() + 1],
      onTap: () => context.go(RoutePaths.installations),
    );

    return ResponsiveBuilder(
      builder: (context, deviceType) {
        if (deviceType == DeviceType.mobile) {
          return Column(
            children: [
              SizedBox(width: double.infinity, height: 150, child: pendingCard),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 150, child: completedCard),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: SizedBox(height: 150, child: pendingCard)),
            const SizedBox(width: 16),
            Expanded(child: SizedBox(height: 150, child: completedCard)),
          ],
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

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M PKR';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K PKR';
    }
    return '${amount.toStringAsFixed(0)} PKR';
  }

  /// Unabbreviated, for the Net Profit reconciliation subtitle. The
  /// abbreviated form above rounds to the nearest thousand, which would make
  /// "142K + 39K − 61K" visibly fail to add up to the headline figure.
  String _formatCurrencyFull(double amount) => 'Rs ${amount.toStringAsFixed(0)}';

  /// States the collection against the accrual yardstick, because the headline
  /// cash figure on its own says nothing about whether the month is on track.
  ///
  /// The two converge to equality once every active subscriber has been
  /// renewed and paid in full, which is the whole point of scoping this card
  /// to the current billing month.
  String _collectionSubtitle(DashboardStatsModel stats) {
    if (stats.subscriberRunRateMargin <= 0) {
      return 'Renewals billed to the current month';
    }
    final pct = ((stats.marginCollectionRate ?? 0) * 100).round();
    final realized = _formatCurrencyFull(stats.currentMonthMarginCollected);
    final target = _formatCurrencyFull(stats.subscriberRunRateMargin);
    if (stats.marginNotYetCollected <= 0) {
      return 'Margin realized $realized — full run rate collected';
    }
    return 'Margin realized $realized of $target run rate · $pct%';
  }

  String _pendingAlertMessage(DashboardStatsModel stats) {
    final clauses = <String>[];
    if (stats.expiredCustomersDueCount > 0) {
      clauses.add(
        '${stats.expiredCustomersDueCount} expired '
        '${stats.expiredCustomersDueCount == 1 ? 'customer has' : 'customers have'} '
        'not been renewed this month '
        '(${_formatCurrency(stats.expiredCustomersDue)})',
      );
    }
    if (stats.currentMonthOutstanding > 0) {
      clauses.add(
        '${_formatCurrency(stats.currentMonthOutstanding)} is outstanding on '
        'part-paid renewals',
      );
    }
    return '${clauses.join(', and ')}.';
  }

  /// Splits the pending figure into its two disjoint causes, since they need
  /// different actions: settle a balance vs. go and renew someone.
  String _pendingSubtitle(DashboardStatsModel stats) {
    final parts = <String>[];
    if (stats.expiredCustomersDueCount > 0) {
      parts.add(
        '${stats.expiredCustomersDueCount} expired awaiting renewal '
        '(${_formatCurrencyFull(stats.expiredCustomersDue)})',
      );
    }
    if (stats.currentMonthOutstanding > 0) {
      parts.add(
        '${_formatCurrencyFull(stats.currentMonthOutstanding)} part-paid',
      );
    }
    return parts.isEmpty ? 'Fully collected for this month' : parts.join(' · ');
  }

  // ===== KPI CARDS (real data-driven) =====
  Widget _buildKPICards(bool isAdmin, DashboardStatsModel stats) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        int columns;
        double aspectRatio;
        switch (deviceType) {
          case DeviceType.mobile:
            columns = 1;
            aspectRatio = 2.1;
            break;
          case DeviceType.tablet:
            columns = 2;
            aspectRatio = 1.6;
            break;
          case DeviceType.desktop:
            columns = 4;
            aspectRatio = 1.35;
            break;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.lg,
          mainAxisSpacing: AppSpacing.lg,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: aspectRatio,
          children: [
            KPICard(
              title: 'Total Customers',
              value: stats.totalCustomers.toString(),
              subtitle: 'Active accounts',
              trend: null,
              isTrendPositive: true,
              icon: Icons.people,
              gradient: AppColors.blueGradient,
              sparklineData: const [2, 3, 5, 4, 7, 6, 8, 9, 8, 10],
            ),
            KPICard(
              title: 'Active Subscribers',
              value: stats.activeCustomers.toString(),
              subtitle: 'Currently active',
              trend: null,
              isTrendPositive: true,
              icon: Icons.check_circle,
              gradient: AppColors.greenGradient,
              sparklineData: const [4, 5, 4, 6, 5, 7, 8, 7, 9, 9],
            ),
            // The next four cards are the accrual chain:
            // Recurring Margin + Installation Profit − Expenses = Net Profit.
            if (isAdmin)
              KPICard(
                title: 'Recurring Margin',
                value: _formatCurrency(stats.subscriberRunRateMargin),
                subtitle: stats.unpricedCustomerCount > 0
                    // Overstated: these customers have no package cost to
                    // subtract, so their full bill is counted as margin.
                    ? 'Overstated · ${stats.unpricedCustomerCount} of ${stats.activeCustomers} have no package cost'
                    : 'Accrual run rate · ${stats.activeCustomers} active subscribers',
                trend: null,
                isTrendPositive: stats.subscriberRunRateMargin >= 0,
                icon: Icons.autorenew,
                gradient: AppColors.greenGradient,
                sparklineData: const [5, 4, 6, 7, 6, 8, 7, 9, 10, 11],
              ),
            if (isAdmin)
              KPICard(
                title: 'Installation Profit',
                value: _formatCurrency(stats.monthlyInstallationProfit),
                subtitle:
                    '${_formatCurrency(stats.monthlyInstallationRevenue)} billed − '
                    '${_formatCurrency(stats.monthlyInstallationCost)} cost · completed this month',
                trend: null,
                isTrendPositive: stats.monthlyInstallationProfit >= 0,
                icon: Icons.engineering,
                gradient: AppColors.orangeGradient,
                sparklineData: const [3, 4, 3, 5, 6, 5, 7, 6, 8, 9],
              ),
            if (isAdmin)
              KPICard(
                title: 'Operating Expenses',
                value: _formatCurrency(stats.monthlyExpenses),
                subtitle: 'Logged this month to date',
                trend: null,
                isTrendPositive: false,
                icon: Icons.receipt,
                gradient: AppColors.redGradient,
                sparklineData: const [8, 7, 6, 5, 4, 3, 4, 5, 4, 3],
              ),
            if (isAdmin)
              KPICard(
                title: 'Net Profit (Accrual)',
                value: _formatCurrency(stats.netProfit),
                // Spells out the arithmetic so the three cards above visibly
                // reconcile to this one even when the grid wraps them onto
                // separate rows.
                subtitle: '${_formatCurrencyFull(stats.subscriberRunRateMargin)}'
                    ' + ${_formatCurrencyFull(stats.monthlyInstallationProfit)}'
                    ' − ${_formatCurrencyFull(stats.monthlyExpenses)}',
                trend: null,
                isTrendPositive: stats.netProfit >= 0,
                icon: Icons.attach_money,
                gradient: AppColors.purpleGradient,
                sparklineData: const [2, 3, 2, 4, 5, 6, 7, 6, 8, 10],
              ),
            // Collected and Pending are both scoped to the CURRENT BILLING
            // MONTH, so they answer "how is this month going" rather than
            // "what has ever landed". Together with Recurring Margin they
            // close the loop: collected margin climbs toward the run rate as
            // renewals come in, and the shortfall is exactly what Pending
            // still has to collect.
            if (isAdmin)
              KPICard(
                title: 'Collected This Month',
                value: _formatCurrency(stats.currentMonthCollected),
                subtitle: _collectionSubtitle(stats),
                trend: null,
                isTrendPositive: true,
                icon: Icons.account_balance_wallet,
                gradient: AppColors.greenGradient,
                sparklineData: const [5, 4, 6, 7, 6, 8, 7, 9, 10, 11],
              ),
            if (isAdmin)
              KPICard(
                title: 'Pending This Month',
                value: _formatCurrency(stats.pendingThisMonth),
                subtitle: _pendingSubtitle(stats),
                trend: null,
                isTrendPositive: false,
                icon: Icons.schedule,
                gradient: AppColors.redGradient,
                sparklineData: const [10, 9, 8, 9, 7, 6, 5, 6, 4, 2],
              ),
            if (isAdmin)
              KPICard(
                title: 'Expired Customers',
                value: stats.expiredCustomers.toString(),
                subtitle: stats.expiredCustomersDueCount > 0
                    ? '${stats.expiredCustomersDueCount} not yet renewed this month'
                    : 'All lapsed accounts have been renewed',
                trend: null,
                isTrendPositive: false,
                icon: Icons.person_off,
                gradient: AppColors.redGradient,
                sparklineData: const [4, 5, 4, 6, 5, 4, 3, 4, 3, 2],
              ),
            if (!isAdmin) ...[
              KPICard(
                title: 'Total Customers',
                value: stats.totalCustomers.toString(),
                subtitle: 'All subscribers',
                trend: null,
                isTrendPositive: true,
                icon: Icons.group,
                gradient: AppColors.blueGradient,
                sparklineData: const [3, 4, 3, 5, 4, 6, 5, 7, 6, 8],
              ),
              KPICard(
                title: 'Expiring Soon',
                value: stats.expiringsoon.toString(),
                subtitle: 'Next 7 days',
                trend: null,
                isTrendPositive: false,
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
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        int columns;
        switch (deviceType) {
          case DeviceType.mobile:
            columns = 2;
            break;
          case DeviceType.tablet:
            columns = 3;
            break;
          case DeviceType.desktop:
            columns = 4;
            break;
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

  // ===== ACTIVITY TIMELINE (real recent payments) =====
  Widget _buildActivityTimeline(List<PaymentModel> recentPayments) {
    final activities = recentPayments.map((p) {
      final date = p.completedDate ?? p.createdAt ?? DateTime.now();
      return ActivityTimelineItem(
        title: 'Payment Received',
        description:
            '${p.customerName ?? p.customerId} paid Rs ${(p.paidAmount ?? p.amount).toStringAsFixed(0)} via ${p.method ?? 'cash'}',
        timestamp: date,
        icon: Icons.check_circle,
        color: AppColors.successGreen,
        badge: 'Payment',
      );
    }).toList();

    if (activities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No recent activity.',
              style: GoogleFonts.inter(color: AppColors.darkGray),
            ),
          ),
        ),
      );
    }

    return ActivityTimelineWidget(
      items: activities,
      title: 'Recent Activity',
      onViewMore: () {},
    );
  }

  // ===== EXPIRING CONTRACTS TABLE (real data-driven) =====
  Widget _buildExpiringTable(List<CustomerModel> customers) {
    if (customers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No expiring contracts in the next 7 days.',
              style: GoogleFonts.inter(color: AppColors.darkGray),
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();

    return ResponsiveTable(
      columns: [
        PremiumDataColumn(label: 'Customer Name'),
        PremiumDataColumn(label: 'Connection Type'),
        PremiumDataColumn(label: 'Due Date'),
        PremiumDataColumn(label: 'Days Left'),
        PremiumDataColumn(label: 'Status', width: 0.8),
        PremiumDataColumn(label: 'Action', width: 0.8),
      ],
      rows: customers.map((customer) {
        final due =
            customer.nextDueDate ??
            (customer.createdAt != null
                ? DateTime(
                    customer.createdAt!.year,
                    customer.createdAt!.month + 1,
                    customer.createdAt!.day,
                  )
                : now);
        final daysLeft = due.difference(now).inDays;

        return PremiumDataRow(
          cells: [
            Text(
              customer.name,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            Text(
              customer.connectionType == 'fiber' ? 'Fiber' : 'Wireless',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            Text('${due.day}/${due.month}/${due.year}'),
            Text(
              daysLeft <= 0 ? 'Today' : '$daysLeft days',
              style: GoogleFonts.inter(
                color: daysLeft <= 3
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
        final customer = customers[index];
        final due =
            customer.nextDueDate ??
            (customer.createdAt != null
                ? DateTime(
                    customer.createdAt!.year,
                    customer.createdAt!.month + 1,
                    customer.createdAt!.day,
                  )
                : now);
        final daysLeft = due.difference(now).inDays;

        return MobileDashboardCard(
          title: customer.name,
          subtitle: customer.connectionType == 'fiber' ? 'Fiber' : 'Wireless',
          statusBadge: const StatusBadge(
            status: StatusType.expiring,
            label: 'Expiring Soon',
          ),
          details: {
            'Due Date': '${due.day}/${due.month}/${due.year}',
            'Days Left': daysLeft <= 0 ? 'Today' : '$daysLeft days',
          },
          actionButton: TextButton(
            onPressed: () => context.go(RoutePaths.customers),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryBlue.withOpacity(0.08),
              foregroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Renew'),
          ),
        );
      },
    );
  }

  // ===== RECENT PAYMENTS TABLE (real data-driven) =====
  Widget _buildRecentPaymentsTable(List<PaymentModel> payments) {
    if (payments.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No recent payments found.',
              style: GoogleFonts.inter(color: AppColors.darkGray),
            ),
          ),
        ),
      );
    }

    return ResponsiveTable(
      columns: [
        PremiumDataColumn(label: 'Customer'),
        PremiumDataColumn(label: 'Method'),
        PremiumDataColumn(label: 'Amount'),
        PremiumDataColumn(label: 'Status', width: 0.8),
        PremiumDataColumn(label: 'Date'),
      ],
      rows: payments.map((payment) {
        final statusType = payment.status == 'paid'
            ? StatusType.completed
            : StatusType.pending;
        final date = payment.completedDate ?? payment.createdAt;
        final dateStr = date != null
            ? '${date.day}/${date.month}/${date.year}'
            : '—';

        return PremiumDataRow(
          cells: [
            Text(
              payment.customerName ?? payment.customerId,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            Text(payment.method ?? '—'),
            Text(
              'Rs ${(payment.paidAmount ?? payment.amount).toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: statusType == StatusType.completed
                    ? AppColors.successGreen
                    : AppColors.warningOrange,
              ),
            ),
            StatusBadge(status: statusType),
            Text(dateStr),
          ],
        );
      }).toList(),
      mobileItemBuilder: (context, index) {
        final payment = payments[index];
        final statusType = payment.status == 'paid'
            ? StatusType.completed
            : StatusType.pending;
        final date = payment.completedDate ?? payment.createdAt;
        final dateStr = date != null
            ? '${date.day}/${date.month}/${date.year}'
            : '—';

        return MobileDashboardCard(
          title: payment.customerName ?? payment.customerId,
          subtitle: payment.method ?? '—',
          statusBadge: StatusBadge(status: statusType),
          details: {
            'Amount':
                'Rs ${(payment.paidAmount ?? payment.amount).toStringAsFixed(0)}',
            'Date': dateStr,
          },
        );
      },
    );
  }
}
