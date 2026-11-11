import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/billing_cycle.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/reports/domain/entities/monthly_financial_summary.dart';
import 'package:nasr_isp/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';

const _kAccent = Color(0xFF0F766E);
const _kInk = Color(0xFF14213D);
const _kMuted = Color(0xFF5B6472);
const _kBorder = Color(0xFFE3E6EB);
const _kGood = Color(0xFF0B5B55);
const _kWarn = Color(0xFFB45309);
const _kBad = Color(0xFFB42318);

String _monthLabel(String key) => BillingCycle.formatMonthKey(key);

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

  /// Rs 45,300 style. Always the full number, with a minus sign if negative.
  String _fmt(num amount) {
    final negative = amount < 0;
    final digits = amount.abs().round().toString();
    final withCommas = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '${negative ? '-' : ''}Rs $withCommas';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!authState.user.isAdmin) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Access Denied. Financial reports are available to administrators only.',
                style: TextStyle(color: _kMuted, fontSize: 16),
              ),
            ),
          );
        }

        return BlocBuilder<ReportsBloc, ReportsState>(
          builder: (context, state) {
            // Month list + current selection, available once loaded.
            List<String>? months;
            String? selectedKey;
            if (state is ReportsLoaded) {
              months = state.availableMonths;
              selectedKey = state.selectedMonthKey;
            } else if (state is ReportsSummaryLoading) {
              months = state.availableMonths;
              selectedKey = state.selectedMonthKey;
            }

            return SingleChildScrollView(
              padding: Responsive.pagePaddingFor(
                Responsive.deviceTypeOf(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header + month picker ─────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reports',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: _kInk,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'What came in, what went out, and what you kept.',
                              style: TextStyle(fontSize: 14, color: _kMuted),
                            ),
                          ],
                        ),
                      ),
                      if (months != null && selectedKey != null) ...[
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 200,
                          child: _buildMonthPicker(months, selectedKey),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (state is ReportsLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
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
                              color: _kBad,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              style: const TextStyle(color: _kMuted),
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
                  else if (state is ReportsLoaded)
                    _buildContent(
                      state.summary,
                      state.previousSummary,
                      state.selectedMonthKey,
                    )
                  else if (state is ReportsSummaryLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Month picker ───────────────────────────────────────────────────────────

  Widget _buildMonthPicker(List<String> months, String selectedKey) {
    // Most recent first, with "All time" pinned at the top.
    final keys = [kAllTimeReportKey, ...months.reversed];
    return DropdownButtonFormField<String>(
      value: selectedKey,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC9CED6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC9CED6)),
        ),
      ),
      items: keys
          .map(
            (key) => DropdownMenuItem(
              value: key,
              child: Text(
                key == kAllTimeReportKey ? 'All time' : _monthLabel(key),
                style: TextStyle(
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
          context.read<ReportsBloc>().add(SelectReportMonthEvent(val));
        }
      },
    );
  }

  // ── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent(
    MonthlyFinancialSummary summary,
    MonthlyFinancialSummary? previous,
    String selectedKey,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary.unpricedCustomerCount > 0) ...[
          _buildWarning(summary.unpricedCustomerCount),
          const SizedBox(height: 16),
        ],
        _buildHero(summary, previous, selectedKey),
        const SizedBox(height: 16),
        _buildSummaryCards(summary),
        const SizedBox(height: 24),
        _buildDetailGrid(summary),
      ],
    );
  }

  Widget _buildWarning(int count) {
    const brown = Color(0xFF7A3E00);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2C98A)),
      ),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 14, color: brown),
          children: [
            const TextSpan(
              text: 'These figures may be too high. ',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text:
                  '$count active '
                  '${count == 1 ? 'subscriber has' : 'subscribers have'} '
                  'no package cost, so their full bill is counted as margin.',
            ),
          ],
        ),
      ),
    );
  }

  // ── Net profit ─────────────────────────────────────────────────────────────

  Widget _buildHero(
    MonthlyFinancialSummary summary,
    MonthlyFinancialSummary? previous,
    String selectedKey,
  ) {
    final isAllTime = selectedKey == kAllTimeReportKey;
    final isProfit = summary.netProfit >= 0;
    const soft = Color(0xFFC9D1E3);

    // Month-over-month change: skipped for all-time, when there is no earlier
    // month, or when last month's profit was exactly zero.
    String? delta;
    if (!isAllTime && previous != null && previous.netProfit != 0) {
      final change =
          ((summary.netProfit - previous.netProfit) /
              previous.netProfit.abs()) *
          100;
      delta =
          '${change >= 0 ? '▲' : '▼'} ${change.abs().toStringAsFixed(0)}%'
          ' vs ${_monthLabel(previous.monthKey)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isProfit ? _kInk : const Color(0xFF7F1D1D),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAllTime
                ? 'Net profit, all time (cash collected)'
                : 'Net profit for ${_monthLabel(selectedKey)} (cash collected)',
            style: const TextStyle(fontSize: 14, color: soft),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _fmt(summary.netProfit),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    delta,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Subscriptions collected ${_fmt(summary.subscriptionCollected)}'
            '  ·  Installation profit ${_fmt(summary.installationProfit)}'
            '  ·  Product sales profit ${_fmt(summary.productSalesProfit)}'
            '  ·  Expenses ${_fmt(summary.totalExpenses)}',
            style: const TextStyle(fontSize: 14, color: soft),
          ),
        ],
      ),
    );
  }

  // ── Three summary cards ────────────────────────────────────────────────────

  Widget _statCard(String label, String value, {String? note, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _kMuted)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color ?? _kInk,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note, style: const TextStyle(fontSize: 12, color: _kMuted)),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards(MonthlyFinancialSummary s) {
    final revenue = s.subscriptionCollected + s.installationRevenue;
    final rate = s.subscriptionBilled > 0
        ? '${(s.subscriptionCollected / s.subscriptionBilled * 100).round()}%'
        : '—';
    return _grid(
      minColumns: 1,
      children: [
        _statCard(
          'Total revenue',
          _fmt(revenue),
          note: 'Subscriptions collected + installations billed',
        ),
        _statCard(
          'Total expenses',
          _fmt(s.totalExpenses),
          note: 'Operating costs',
          color: s.totalExpenses > 0 ? _kBad : null,
        ),
        _statCard(
          'Collection rate',
          rate,
          note: 'Collected out of billed',
          color: _kAccent,
        ),
      ],
    );
  }

  /// Equal-width cards: 3 per row when wide, 2 on medium, 1 on phones.
  Widget _grid({required List<Widget> children, int minColumns = 1}) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 16.0;
        final cols = c.maxWidth >= 1000
            ? 3
            : (c.maxWidth >= 640 ? 2 : minColumns);
        final width = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }

  // ── Detail cards ───────────────────────────────────────────────────────────

  Widget _buildDetailGrid(MonthlyFinancialSummary s) {
    return _grid(
      children: [
        _buildSubscriptionCard(s),
        _buildInstallationCard(s),
        _buildProductSalesCard(s),
        _buildExpensesCard(s),
      ],
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    Color color = _kInk,
    bool bold = false,
    String? note,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: _kInk,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          if (note != null)
            Text(note, style: const TextStyle(fontSize: 12, color: _kMuted)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(MonthlyFinancialSummary s) {
    final outstanding = (s.subscriptionBilled - s.subscriptionCollected).clamp(
      0,
      double.infinity,
    );
    final pct = s.subscriptionBilled > 0
        ? (s.subscriptionCollected / s.subscriptionBilled).clamp(0.0, 1.0)
        : 0.0;
    return _sectionCard('Subscriptions', [
      _row('Billed', _fmt(s.subscriptionBilled), note: 'Charged on renewals'),
      _row(
        'Collected',
        _fmt(s.subscriptionCollected),
        color: _kGood,
        bold: true,
      ),
      _row('Outstanding', _fmt(outstanding), color: _kWarn),
      if (s.subscriptionBilled > 0) ...[
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.toDouble(),
            minHeight: 8,
            backgroundColor: _kBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(pct * 100).round()}% collected',
          style: const TextStyle(fontSize: 12, color: _kMuted),
        ),
      ],
    ]);
  }

  Widget _buildInstallationCard(MonthlyFinancialSummary s) {
    return _sectionCard('Installations', [
      _row(
        'Billed',
        _fmt(s.installationRevenue),
        note: 'Setup fees + materials at sell price',
      ),
      _row(
        'Cost',
        _fmt(s.installationCost),
        color: s.installationCost > 0 ? _kBad : _kInk,
        note: 'Materials at cost + labour',
      ),
      const Divider(height: 20),
      _row(
        'Profit',
        _fmt(s.installationProfit),
        color: s.installationProfit >= 0 ? _kGood : _kBad,
        bold: true,
      ),
    ]);
  }

  Widget _buildProductSalesCard(MonthlyFinancialSummary s) {
    return _sectionCard('Product Sales', [
      _row(
        'Revenue',
        _fmt(s.productSalesRevenue),
        note: '${s.productSalesCount} sales · ${s.productSalesUnits} units sold',
      ),
      _row(
        'Cost',
        _fmt(s.productSalesCost),
        color: s.productSalesCost > 0 ? _kBad : _kInk,
        note: 'Cost snapshot at time of sale',
      ),
      const Divider(height: 20),
      _row(
        'Profit',
        _fmt(s.productSalesProfit),
        color: s.productSalesProfit >= 0 ? _kGood : _kBad,
        bold: true,
      ),
    ]);
  }

  Widget _buildExpensesCard(MonthlyFinancialSummary s) {
    // Largest expense first: easiest to see what is driving costs.
    final categories =
        ExpenseCategory.values
            .where((cat) => (s.expensesByCategory[cat] ?? 0) > 0)
            .toList()
          ..sort(
            (a, b) => (s.expensesByCategory[b] ?? 0).compareTo(
              s.expensesByCategory[a] ?? 0,
            ),
          );
    final maxValue = categories.isEmpty
        ? 0.0
        : s.expensesByCategory[categories.first]!;

    return _sectionCard('Expenses', [
      if (categories.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'No expenses recorded for this period.',
            style: TextStyle(fontSize: 14, color: _kMuted),
          ),
        )
      else ...[
        for (final cat in categories)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _expenseBar(
              cat.label,
              _fmt(s.expensesByCategory[cat]!),
              maxValue > 0 ? s.expensesByCategory[cat]! / maxValue : 0.0,
            ),
          ),
        const Divider(height: 20),
        _row('Total', _fmt(s.totalExpenses), color: _kBad, bold: true),
      ],
    ]);
  }

  /// Bar width is proportional to the largest category.
  Widget _expenseBar(String label, String value, double fraction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: _kInk)),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kInk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: _kBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(_kBad),
          ),
        ),
      ],
    );
  }
}
