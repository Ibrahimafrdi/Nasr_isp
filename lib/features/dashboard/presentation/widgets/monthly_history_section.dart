import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/config/service_locator.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/billing_cycle.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/features/reports/domain/entities/monthly_financial_summary.dart';
import 'package:nasr_isp/features/reports/domain/usecases/get_available_report_months.dart';
import 'package:nasr_isp/features/reports/domain/usecases/get_monthly_financial_summary.dart';
import 'package:nasr_isp/shared/widgets/mobile_dashboard_card.dart';
import 'package:nasr_isp/shared/widgets/premium_data_table.dart';
import 'package:nasr_isp/shared/widgets/responsive_table.dart';

/// Monthly History section for the Dashboard.
///
/// Displays historical financial summaries in a clean data table.
/// Ordered by default with the latest month first, with toggleable sorting.
class MonthlyHistorySection extends StatefulWidget {
  const MonthlyHistorySection({Key? key}) : super(key: key);

  @override
  State<MonthlyHistorySection> createState() => _MonthlyHistorySectionState();
}

class _MonthlyHistorySectionState extends State<MonthlyHistorySection> {
  late Future<List<MonthlyFinancialSummary>> _summariesFuture;
  bool _latestFirst = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _summariesFuture = _fetchMonthlySummaries();
  }

  Future<List<MonthlyFinancialSummary>> _fetchMonthlySummaries() async {
    final getMonths = getIt<GetAvailableReportMonths>();
    final getSummary = getIt<GetMonthlyFinancialSummary>();

    final months = await getMonths();
    if (months.isEmpty) return [];

    final summaries = await Future.wait(
      months.map((m) {
        final parts = m.split('-');
        final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        return getSummary(dt);
      }),
    );

    return summaries;
  }

  String _formatCurrency(double amount) =>
      'Rs ${amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          )}';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MonthlyFinancialSummary>>(
      future: _summariesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.lightGray),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.lightGray),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 36,
                      color: AppColors.errorRed,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load monthly history',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _loadData();
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.lightGray),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No monthly records found.',
                  style: GoogleFonts.inter(color: AppColors.darkGray),
                ),
              ),
            ),
          );
        }

        final sortedList = _latestFirst
            ? (List<MonthlyFinancialSummary>.from(data)..sort((a, b) => b.monthKey.compareTo(a.monthKey)))
            : (List<MonthlyFinancialSummary>.from(data)..sort((a, b) => a.monthKey.compareTo(b.monthKey)));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Monthly History',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${sortedList.length} ${sortedList.length == 1 ? 'month' : 'months'})',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.darkGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _latestFirst = !_latestFirst;
                        });
                      },
                      icon: Icon(
                        _latestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 16,
                      ),
                      label: Text(
                        _latestFirst ? 'Latest First' : 'Oldest First',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => context.go(RoutePaths.reports),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(
                        'Full Reports',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveTable(
              columns: [
                PremiumDataColumn(label: 'Month'),
                PremiumDataColumn(label: 'Revenue'),
                PremiumDataColumn(label: 'Expenses'),
                PremiumDataColumn(label: 'Net Profit'),
              ],
              rows: sortedList.map((summary) {
                final totalRevenue =
                    summary.subscriptionCollected + summary.installationRevenue;
                final isNetPositive = summary.netProfit >= 0;
                return PremiumDataRow(
                  cells: [
                    Text(
                      BillingCycle.formatMonthKey(summary.monthKey),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    Text(
                      _formatCurrency(totalRevenue),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    Text(
                      _formatCurrency(summary.totalExpenses),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        color: AppColors.charcoal,
                      ),
                    ),
                    Text(
                      _formatCurrency(summary.netProfit),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: isNetPositive
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                      ),
                    ),
                  ],
                );
              }).toList(),
              mobileItemBuilder: (context, index) {
                final summary = sortedList[index];
                final totalRevenue =
                    summary.subscriptionCollected + summary.installationRevenue;
                final isNetPositive = summary.netProfit >= 0;

                return MobileDashboardCard(
                  title: BillingCycle.formatMonthKey(summary.monthKey),
                  subtitle: isNetPositive ? 'Profitable' : 'Deficit',
                  details: {
                    'Revenue': _formatCurrency(totalRevenue),
                    'Expenses': _formatCurrency(summary.totalExpenses),
                    'Net Profit': _formatCurrency(summary.netProfit),
                  },
                  actionButton: TextButton(
                    onPressed: () => context.go(RoutePaths.reports),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.08),
                      foregroundColor: AppColors.primaryBlue,
                    ),
                    child: const Text('View Details'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
