import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/widgets/premium_data_table.dart';
import 'package:nasr_isp/shared/widgets/status_badge.dart';
import 'package:nasr_isp/shared/widgets/responsive_table.dart';
import 'package:nasr_isp/shared/widgets/mobile_dashboard_card.dart';

const _kAccent = Color(0xFF0F766E);
const _kInk = Color(0xFF14213D);
const _kBorder = Color(0xFFE3E6EB);
const _kMuted = Color(0xFF5B6472);

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
                  valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
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
                      onPressed: () => context.read<DashboardBloc>().add(
                        const LoadDashboardEvent(),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final loaded = state is DashboardLoaded ? state : null;
            final stats =
                loaded?.stats ??
                const DashboardStatsModel(
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
                );

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // ===== HEADER + QUICK ACTIONS =====
                        Column(
                          children: [
                            Text(
                              'Good ${_getGreeting()}, ${user.name}',
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: _kInk,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAdmin
                                  ? '       Here is how your internet business is doing this month.'
                                  : '       Employee Performance Metrics',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: _kMuted,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const SizedBox(width: 16),
                        _buildQuickActions(context),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ===== NEEDS ATTENTION (admin) =====
                    if (isAdmin && loaded != null) ...[
                      _buildAttentionBar(context, stats),
                    ],

                    // ===== MONEY (admin) =====
                    if (isAdmin) ...[
                      const _SectionTitle('Money this month'),

                      const SizedBox(height: 16),
                      _buildNetProfit(stats),
                      _cardGrid([
                        _StatCard(
                          label: 'Monthly revenue',
                          value: _rs(stats.subscriberRunRateRevenue),
                          note: 'Billed to ${stats.activeCustomers} customers',
                        ),
                        _StatCard(
                          label: 'Vendor cost',
                          value: _rs(stats.subscriberVendorCost),
                          note: 'What you pay for the packages',
                        ),
                        _StatCard(
                          label: 'Margin (revenue minus cost)',
                          value: _rs(stats.subscriberRunRateMargin),
                          valueColor: _kAccent,
                          note: stats.unpricedCustomerCount > 0
                              ? 'Overstated · ${stats.unpricedCustomerCount} of ${stats.activeCustomers} have no package cost'
                              : _marginPercentNote(stats),
                        ),
                        _StatCard(
                          label: 'Collected so far',
                          value: _rs(stats.currentMonthCollected),
                          progress: stats.marginCollectionRate ?? 0,
                          note: _collectionSubtitle(stats),
                        ),
                      ]),
                      const SizedBox(height: 32),
                    ],

                    // ===== CUSTOMERS =====
                    const _SectionTitle('Customers'),
                    _cardGrid([
                      _StatCard(
                        label: 'Total customers',
                        value: stats.totalCustomers.toString(),
                      ),
                      _StatCard(
                        label: 'Expiring in 7 days',
                        value: stats.expiringsoon.toString(),
                        valueColor: AppColors.warningOrange,
                      ),
                      if (isAdmin) ...[
                        _StatCard(
                          label: 'Expired, not renewed',
                          value: stats.expiredCustomersDueCount.toString(),
                          valueColor: AppColors.errorRed,
                          note: '${stats.expiredCustomers} expired in total',
                        ),
                        _StatCard(
                          label: 'Waiting to be paid',
                          value: _rs(stats.pendingThisMonth),
                          valueColor: AppColors.errorRed,
                          note: _pendingSubtitle(stats),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 32),

                    // ===== TABLES (admin) =====
                    if (isAdmin) ...[
                      _SectionTitle(
                        'Renew soon (next 7 days)',
                        actionLabel: 'See all customers',
                        onAction: () => context.go(RoutePaths.customers),
                      ),
                      _buildExpiringTable(
                        (loaded?.expiringCustomers ?? <CustomerModel>[])
                            .take(5)
                            .toList(),
                      ),
                      const SizedBox(height: 32),
                      _SectionTitle(
                        'Recent payments',
                        actionLabel: 'See all payments',
                        onAction: () => context.go(RoutePaths.payments),
                      ),
                      _buildRecentPaymentsTable(
                        (loaded?.recentPayments ?? <PaymentModel>[])
                            .take(5)
                            .toList(),
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

  // ===== helpers =====
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  /// Rs 420,686 style, always the full number so the cards add up.
  String _rs(double amount) {
    final digits = amount.round().toString();
    final withCommas = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return 'Rs $withCommas';
  }

  String _marginPercentNote(DashboardStatsModel s) {
    if (s.subscriberRunRateRevenue <= 0) return 'Revenue minus vendor cost';
    final pct = (s.subscriberRunRateMargin / s.subscriberRunRateRevenue * 100)
        .round();
    return '$pct% of revenue';
  }

  String _collectionSubtitle(DashboardStatsModel stats) {
    if (stats.subscriberRunRateMargin <= 0) {
      return 'Renewals billed to the current month';
    }
    final pct = ((stats.marginCollectionRate ?? 0) * 100).round();
    final realized = _rs(stats.currentMonthMarginCollected);
    final target = _rs(stats.subscriberRunRateMargin);
    if (stats.marginNotYetCollected <= 0) {
      return 'Margin realized $realized, full run rate collected';
    }
    return 'Margin realized $realized of $target · $pct%';
  }

  String _pendingAlertMessage(DashboardStatsModel stats) {
    final clauses = <String>[];
    if (stats.expiredCustomersDueCount > 0) {
      clauses.add(
        '${stats.expiredCustomersDueCount} expired '
        '${stats.expiredCustomersDueCount == 1 ? 'customer has' : 'customers have'} '
        'not renewed this month (${_rs(stats.expiredCustomersDue)})',
      );
    }
    if (stats.currentMonthOutstanding > 0) {
      clauses.add(
        '${_rs(stats.currentMonthOutstanding)} is outstanding on part-paid renewals',
      );
    }
    return '${clauses.join(', and ')}.';
  }

  String _pendingSubtitle(DashboardStatsModel stats) {
    final parts = <String>[];
    if (stats.expiredCustomersDueCount > 0) {
      parts.add(
        '${stats.expiredCustomersDueCount} expired awaiting renewal '
        '(${_rs(stats.expiredCustomersDue)})',
      );
    }
    if (stats.currentMonthOutstanding > 0) {
      parts.add('${_rs(stats.currentMonthOutstanding)} part-paid');
    }
    return parts.isEmpty ? 'Fully collected for this month' : parts.join(' · ');
  }

  /// Cards sit in rows of 4 / 2 / 1 depending on the available width.
  Widget _cardGrid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 16.0;
        final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 560 ? 2 : 1);
        final width = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }

  // ===== QUICK ACTIONS =====
  Widget _buildQuickActions(BuildContext context) {
    final outlined = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      foregroundColor: _kInk,
      side: const BorderSide(color: Color(0xFFC9CED6)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
    );
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton(
          style: outlined,
          onPressed: () => context.go(RoutePaths.addCustomer),
          child: const Text('Add customer'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 44),
            backgroundColor: _kAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          onPressed: () => context.go(RoutePaths.payments),
          child: const Text('Collect payment'),
        ),
        OutlinedButton(
          style: outlined,
          onPressed: () => context.go(RoutePaths.expenses),
          child: const Text('Add expense'),
        ),
        OutlinedButton(
          style: outlined,
          onPressed: () => context.go(RoutePaths.inventory),
          child: const Text('Add stock'),
        ),
      ],
    );
  }

  // ===== ONE ATTENTION BAR (replaces the two alert banners) =====
  Widget _buildAttentionBar(BuildContext context, DashboardStatsModel stats) {
    final hasExpiring = stats.expiringsoon > 0;
    final hasPending = stats.pendingThisMonth > 0;
    if (!hasExpiring && !hasPending) return const SizedBox.shrink();

    final lines = <String>[
      if (hasExpiring)
        '${stats.expiringsoon} customers expire in the next 7 days.',
      if (hasPending) _pendingAlertMessage(stats),
    ];
    const brown = Color(0xFF7A3E00);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2C98A)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Needs your attention',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: brown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lines.join(' '),
                  style: GoogleFonts.inter(fontSize: 14, color: brown),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (hasExpiring)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: brown,
                    side: const BorderSide(color: brown),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => context.go(RoutePaths.customers),
                  child: const Text('Review expiring'),
                ),
              if (hasPending)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: brown,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => context.go(
                    stats.expiredCustomersDueCount > 0
                        ? RoutePaths.customers
                        : RoutePaths.payments,
                  ),
                  child: Text(
                    stats.expiredCustomersDueCount > 0
                        ? 'Renew expired'
                        : 'Collect payment',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== NET PROFIT (shows the sum; installations and expenses live here) =====
  Widget _buildNetProfit(DashboardStatsModel stats) {
    const soft = Color(0xFFC9D1E3);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kInk,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net profit this month',
            style: GoogleFonts.inter(fontSize: 14, color: soft),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _rs(stats.netProfit),
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '= margin ${_rs(stats.subscriberRunRateMargin)}'
                ' + installations ${_rs(stats.monthlyInstallationProfit)}'
                ' − expenses ${_rs(stats.monthlyExpenses)}',
                style: GoogleFonts.inter(fontSize: 14, color: soft),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== RENEW SOON TABLE =====
  Widget _buildExpiringTable(List<CustomerModel> customers) {
    if (customers.isEmpty) {
      return _emptyCard('No expiring contracts in the next 7 days.');
    }

    final now = DateTime.now();
    DateTime dueOf(CustomerModel c) =>
        c.nextDueDate ??
        (c.createdAt != null
            ? DateTime(
                c.createdAt!.year,
                c.createdAt!.month + 1,
                c.createdAt!.day,
              )
            : now);

    return ResponsiveTable(
      columns: [
        PremiumDataColumn(label: 'Customer'),
        PremiumDataColumn(label: 'Due Date'),
        PremiumDataColumn(label: 'Days Left'),
        PremiumDataColumn(label: 'Action', width: 0.8),
      ],
      rows: customers.map((customer) {
        final due = dueOf(customer);
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
            TextButton(
              onPressed: () => context.go(RoutePaths.customers),
              style: TextButton.styleFrom(
                foregroundColor: _kAccent,
                minimumSize: const Size(64, 44),
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
        final due = dueOf(customer);
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
              backgroundColor: _kAccent.withOpacity(0.08),
              foregroundColor: _kAccent,
              minimumSize: const Size(64, 44),
            ),
            child: const Text('Renew'),
          ),
        );
      },
    );
  }

  // ===== RECENT PAYMENTS TABLE =====
  Widget _buildRecentPaymentsTable(List<PaymentModel> payments) {
    if (payments.isEmpty) return _emptyCard('No recent payments found.');

    String dateOf(PaymentModel p) {
      final d = p.completedDate ?? p.createdAt;
      return d != null ? '${d.day}/${d.month}/${d.year}' : '—';
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
              _rs((payment.paidAmount ?? payment.amount).toDouble()),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: statusType == StatusType.completed
                    ? AppColors.successGreen
                    : AppColors.warningOrange,
              ),
            ),
            StatusBadge(status: statusType),
            Text(dateOf(payment)),
          ],
        );
      }).toList(),
      mobileItemBuilder: (context, index) {
        final payment = payments[index];
        final statusType = payment.status == 'paid'
            ? StatusType.completed
            : StatusType.pending;
        return MobileDashboardCard(
          title: payment.customerName ?? payment.customerId,
          subtitle: payment.method ?? '—',
          statusBadge: StatusBadge(status: statusType),
          details: {
            'Amount': _rs((payment.paidAmount ?? payment.amount).toDouble()),
            'Date': dateOf(payment),
          },
        );
      },
    );
  }

  Widget _emptyCard(String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(color: AppColors.darkGray),
          ),
        ),
      ),
    );
  }
}

// ===== small private widgets =====

class _SectionTitle extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionTitle(this.text, {this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kInk,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: _kAccent,
                minimumSize: const Size(0, 44),
              ),
              child: Text(
                actionLabel!,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? note;
  final Color? valueColor;
  final double? progress;
  const _StatCard({
    required this.label,
    required this.value,
    this.note,
    this.valueColor,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: _kMuted)),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: valueColor ?? _kInk,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: _kBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
              ),
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(note!, style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
          ],
        ],
      ),
    );
  }
}
