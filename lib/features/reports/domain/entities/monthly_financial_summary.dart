import 'package:equatable/equatable.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';

/// A fully-computed financial position for a single calendar month.
///
/// Both accrual (subscriptionBilled) and cash (subscriptionCollected) figures
/// are carried so callers can choose which basis to display without recomputing.
///
/// [netProfit] is cash-collected basis:
///   subscriptionCollected + installationProfit − totalExpenses
class MonthlyFinancialSummary extends Equatable {
  /// `YYYY-MM` key for this month (e.g. `'2026-09'`).
  final String monthKey;

  // ── Subscription ────────────────────────────────────────────────────────────

  /// Sum of `PaymentEntity.amount` for all subscription charges whose
  /// `billingMonth` equals [monthKey].
  final double subscriptionBilled;

  /// Sum of `PaymentEntity.paidAmount` for all subscription charges whose
  /// `billingMonth` equals [monthKey].
  final double subscriptionCollected;

  // ── Installations ────────────────────────────────────────────────────────────

  /// Total billed to customers for completed installations in this month
  /// (setup fee + materials at sell price).
  final double installationRevenue;

  /// Total cost incurred for completed installations in this month
  /// (materials at cost + labour).
  final double installationCost;

  /// installationRevenue − installationCost
  double get installationProfit => installationRevenue - installationCost;

  // ── Expenses ─────────────────────────────────────────────────────────────────

  /// Sum of all expenses whose `date` falls in this month.
  final double totalExpenses;

  /// Expense total broken down by [ExpenseCategory].
  final Map<ExpenseCategory, double> expensesByCategory;

  // ── Summary ──────────────────────────────────────────────────────────────────

  /// Cash-collected net profit:
  ///   subscriptionCollected + installationProfit − totalExpenses
  final double netProfit;

  /// Number of active subscribers whose package cost cannot be resolved.
  /// When > 0 the [subscriptionBilled] and subscriber-margin figures are
  /// overstated (zero cost is used, so the full bill is counted as margin).
  final int unpricedCustomerCount;

  const MonthlyFinancialSummary({
    required this.monthKey,
    required this.subscriptionBilled,
    required this.subscriptionCollected,
    required this.installationRevenue,
    required this.installationCost,
    required this.totalExpenses,
    required this.expensesByCategory,
    required this.netProfit,
    required this.unpricedCustomerCount,
  });

  @override
  List<Object?> get props => [
        monthKey,
        subscriptionBilled,
        subscriptionCollected,
        installationRevenue,
        installationCost,
        totalExpenses,
        expensesByCategory,
        netProfit,
        unpricedCustomerCount,
      ];
}
