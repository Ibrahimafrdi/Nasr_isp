import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/finance/billing_cycle.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/reports/domain/entities/monthly_financial_summary.dart';
import 'package:nasr_isp/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
import 'package:nasr_isp/shared/widgets/alert_panel.dart';

String _formatMonthKey(String key) => BillingCycle.formatMonthKey(key);

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(const LoadReportsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: CircularProgressIndicator());
        }

        return BlocBuilder<ReportsBloc, ReportsState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Row(
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        color: AppColors.primaryBlue,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Financial Reports',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                          Text(
                            'Subscription revenue, installation margins, and expenses by month',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.darkGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  if (state is ReportsLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    )
                  else if (state is ReportsError)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 80),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.errorRed,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              style: GoogleFonts.inter(
                                color: AppColors.darkGray,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.read<ReportsBloc>().add(
                                const LoadReportsEvent(),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (state is ReportsLoaded ||
                      state is ReportsSummaryLoading)
                    _buildContent(state),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent(ReportsState state) {
    final List<String> months;
    final String selectedKey;
    final MonthlyFinancialSummary? summary;
    final MonthlyFinancialSummary? previousSummary;
    final bool summaryLoading;

    if (state is ReportsLoaded) {
      months = state.availableMonths;
      selectedKey = state.selectedMonthKey;
      summary = state.summary;
      previousSummary = state.previousSummary;
      summaryLoading = false;
    } else if (state is ReportsSummaryLoading) {
      months = state.availableMonths;
      selectedKey = state.selectedMonthKey;
      summary = null;
      previousSummary = null;
      summaryLoading = true;
    } else {
      return const SizedBox.shrink();
    }

    // Most-recent first for the dropdown display, with "All Time" pinned
    // at the very top as the broadest view.
    final dropdownKeys = [kAllTimeReportKey, ...months.reversed];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Month Selector ──────────────────────────────────────────────────
        _buildMonthSelector(dropdownKeys, selectedKey),
        const SizedBox(height: 24),

        if (summaryLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          )
        else if (summary != null) ...[
          // ── Unpriced-customer warning ─────────────────────────────────────
          if (summary.unpricedCustomerCount > 0) ...[
            AlertPanel(
              type: AlertType.warning,
              title: 'Revenue figures may be overstated',
              message:
                  '${summary.unpricedCustomerCount} active '
                  '${summary.unpricedCustomerCount == 1 ? 'subscriber has' : 'subscribers have'} '
                  'no package cost assigned. Their full bill is counted as margin, '
                  'which inflates the subscription revenue and net profit figures below.',
              icon: Icons.warning_amber,
            ),
            const SizedBox(height: 20),
          ],

          // ── Hero: Net Profit ────────────────────────────────────────────
          _buildHeroProfitCard(summary, previousSummary, selectedKey),
          const SizedBox(height: 16),

          // ── Slim supporting stat row ─────────────────────────────────────
          _buildStatPairRow(summary),
          const SizedBox(height: 24),

          // ── Detailed breakdown ───────────────────────────────────────────
          _buildDetailCards(summary),
        ],
      ],
    );
  }

  // ── Month Selector ──────────────────────────────────────────────────────────

  Widget _buildMonthSelector(List<String> dropdownKeys, String selectedKey) {
    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightGray),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: AppColors.primaryBlue),
            const SizedBox(width: 12),
            Text(
              'Reporting Month',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedKey,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.lightGray),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.lightGray),
                  ),
                ),
                items: dropdownKeys
                    .map(
                      (key) => DropdownMenuItem(
                        value: key,
                        child: Text(
                          key == kAllTimeReportKey
                              ? 'All Time'
                              : _formatMonthKey(key),
                          style: GoogleFonts.inter(
                            fontWeight: key == kAllTimeReportKey
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    context.read<ReportsBloc>().add(
                      SelectReportMonthEvent(val),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Net Profit Card ─────────────────────────────────────────────────────

  Widget _buildHeroProfitCard(
    MonthlyFinancialSummary summary,
    MonthlyFinancialSummary? previousSummary,
    String selectedKey,
  ) {
    final isProfit = summary.netProfit >= 0;
    final gradientColors = isProfit
        ? AppColors.greenGradient
        : AppColors.redGradient;

    final isAllTime = selectedKey == kAllTimeReportKey;

    // Month-over-month delta — omitted entirely for the all-time view,
    // if there's no prior month to compare against, or the previous
    // month's net profit was exactly zero (a percentage change against
    // zero is meaningless).
    String? deltaText;
    bool? deltaIsUp;
    if (!isAllTime &&
        previousSummary != null &&
        previousSummary.netProfit != 0) {
      final change =
          ((summary.netProfit - previousSummary.netProfit) /
              previousSummary.netProfit.abs()) *
          100;
      deltaIsUp = change >= 0;
      final prevLabel = _formatMonthKey(previousSummary.monthKey);
      deltaText =
          '${deltaIsUp ? '▲' : '▼'} ${change.abs().toStringAsFixed(0)}% vs $prevLabel';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAllTime
                      ? 'Net Profit — All Time (Cash Collected Basis)'
                      : 'Net Profit — Cash Collected Basis',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _fmt(summary.netProfit),
                  style: GoogleFonts.inter(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          if (deltaText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                deltaText,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Slim supporting stat row (Revenue / Expenses) ────────────────────────────

  Widget _buildStatPairRow(MonthlyFinancialSummary summary) {
    final totalRevenue =
        summary.subscriptionCollected + summary.installationRevenue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatBlock(
              label: 'Total Revenue',
              value: _fmt(totalRevenue),
              subtitle: 'Collected + installation',
              color: AppColors.primaryBlue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.lightGray,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: _StatBlock(
              label: 'Total Expenses',
              value: _fmt(summary.totalExpenses),
              subtitle: 'Operating costs this month',
              color: AppColors.errorRed,
            ),
          ),
        ],
      ),
    );
  }

  // ── Detailed Breakdown Cards ────────────────────────────────────────────────

  Widget _buildDetailCards(MonthlyFinancialSummary summary) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final leftColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubscriptionCard(summary),
            const SizedBox(height: 16),
            _buildInstallationCard(summary),
          ],
        );

        final rightColumn = _buildExpensesCard(summary);

        if (deviceType == DeviceType.mobile) {
          return Column(
            children: [leftColumn, const SizedBox(height: 16), rightColumn],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: leftColumn),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: rightColumn),
          ],
        );
      },
    );
  }

  Widget _buildSubscriptionCard(MonthlyFinancialSummary summary) {
    return _SectionCard(
      title: 'Subscription Revenue',
      icon: Icons.autorenew,
      iconColor: AppColors.primaryBlue,
      children: [
        _DetailRow(
          label: 'Billed this month',
          value: _fmt(summary.subscriptionBilled),
          valueColor: AppColors.charcoal,
          tooltip: 'Total charged on subscription renewals',
        ),
        const Divider(height: 20),
        _DetailRow(
          label: 'Collected',
          value: _fmt(summary.subscriptionCollected),
          valueColor: AppColors.successGreen,
          bold: true,
        ),
        const SizedBox(height: 8),
        _DetailRow(
          label: 'Outstanding',
          value: _fmt(
            (summary.subscriptionBilled - summary.subscriptionCollected).clamp(
              0,
              double.infinity,
            ),
          ),
          valueColor: AppColors.warningOrange,
        ),
        if (summary.subscriptionBilled > 0) ...[
          const SizedBox(height: 12),
          _CollectionBar(
            collected: summary.subscriptionCollected,
            billed: summary.subscriptionBilled,
          ),
        ],
      ],
    );
  }

  Widget _buildInstallationCard(MonthlyFinancialSummary summary) {
    return _SectionCard(
      title: 'Installation Revenue',
      icon: Icons.engineering,
      iconColor: AppColors.warningOrange,
      children: [
        _DetailRow(
          label: 'Revenue billed',
          value: _fmt(summary.installationRevenue),
          valueColor: AppColors.charcoal,
          tooltip: 'Setup fees + materials at sell price',
        ),
        const SizedBox(height: 4),
        _DetailRow(
          label: 'Cost incurred',
          value: _fmt(summary.installationCost),
          valueColor: AppColors.errorRed,
          tooltip: 'Materials at cost + labour',
        ),
        const Divider(height: 20),
        _DetailRow(
          label: 'Installation Profit',
          value: _fmt(summary.installationProfit),
          valueColor: summary.installationProfit >= 0
              ? AppColors.successGreen
              : AppColors.errorRed,
          bold: true,
        ),
      ],
    );
  }

  Widget _buildExpensesCard(MonthlyFinancialSummary summary) {
    final categoriesWithSpend =
        ExpenseCategory.values
            .where((cat) => (summary.expensesByCategory[cat] ?? 0) > 0)
            .toList()
          // Largest expense first — easiest to scan what's driving costs.
          ..sort(
            (a, b) => (summary.expensesByCategory[b] ?? 0).compareTo(
              summary.expensesByCategory[a] ?? 0,
            ),
          );

    final maxValue = categoriesWithSpend.isEmpty
        ? 0.0
        : summary.expensesByCategory[categoriesWithSpend.first]!;

    return _SectionCard(
      title: 'Operating Expenses',
      icon: Icons.receipt_long,
      iconColor: AppColors.errorRed,
      children: [
        if (categoriesWithSpend.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No expenses recorded this month.',
              style: GoogleFonts.inter(color: AppColors.mediumGray),
            ),
          )
        else
          ...categoriesWithSpend.map((cat) {
            final value = summary.expensesByCategory[cat]!;
            final fraction = maxValue > 0 ? value / maxValue : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ExpenseBarRow(
                label: cat.label,
                value: _fmt(value),
                fraction: fraction,
              ),
            );
          }),
        if (categoriesWithSpend.isNotEmpty) ...[
          const Divider(height: 20),
          _DetailRow(
            label: 'Total Expenses',
            value: _fmt(summary.totalExpenses),
            valueColor: AppColors.errorRed,
            bold: true,
          ),
        ],
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _fmt(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M PKR';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K PKR';
    }
    return 'Rs ${amount.toStringAsFixed(0)}';
  }

  String _formatMonthKey(String key) {
    final parts = key.split('-');
    if (parts.length < 2) return key;
    final year = parts[0];
    final month = int.tryParse(parts[1]) ?? 0;
    const monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final name = month >= 1 && month <= 12 ? monthNames[month] : '?';
    return '$name $year';
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

/// One half of the slim supporting stat row below the hero card.
class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _StatBlock({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.mediumGray),
        ),
      ],
    );
  }
}

/// A horizontal bar for one expense category — width proportional to its
/// share of the largest category this month, so relative cost drivers are
/// visible at a glance without a charting package.
class _ExpenseBarRow extends StatelessWidget {
  final String label;
  final String value;
  final double fraction;

  const _ExpenseBarRow({
    required this.label,
    required this.value,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 6,
                    width: constraints.maxWidth,
                    color: AppColors.lightGray,
                  ),
                  Container(
                    height: 6,
                    width: constraints.maxWidth * fraction.clamp(0.0, 1.0),
                    color: AppColors.errorRed,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;
  final String? tooltip;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.darkGray,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        tooltip != null
            ? Tooltip(message: tooltip!, child: labelWidget)
            : labelWidget,
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _CollectionBar extends StatelessWidget {
  final double collected;
  final double billed;

  const _CollectionBar({required this.collected, required this.billed});

  @override
  Widget build(BuildContext context) {
    final pct = billed > 0 ? (collected / billed).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Collection rate',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.mediumGray,
              ),
            ),
            Text(
              '${(pct * 100).round()}%',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: pct >= 1.0
                    ? AppColors.successGreen
                    : AppColors.warningOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppColors.lightGray,
            valueColor: AlwaysStoppedAnimation<Color>(
              pct >= 1.0 ? AppColors.successGreen : AppColors.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }
}
