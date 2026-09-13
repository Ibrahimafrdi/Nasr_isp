import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/features/customers/domain/usecases/get_customers.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/get_expenses.dart';
import 'package:nasr_isp/features/installations/domain/usecases/get_installations.dart';
import 'package:nasr_isp/features/installations/domain/utils/installation_aggregates.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/domain/usecases/get_packages.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_all_payments.dart';
import 'package:nasr_isp/features/reports/domain/entities/monthly_financial_summary.dart';

/// Computes a [MonthlyFinancialSummary] for any given calendar month.
///
/// Reuses [MoneyLine], [BillingCycle], [completedInMonth], and
/// [installationsMoney] exactly as [DashboardBloc] does — no math is
/// reimplemented, only parameterised.
///
/// All five repository reads are performed here so the usecase is self-
/// contained and testable in isolation.
class GetMonthlyFinancialSummary {
  final GetCustomers getCustomers;
  final GetAllPayments getAllPayments;
  final GetExpenses getExpenses;
  final GetInstallations getInstallations;
  final GetPackages getPackages;

  const GetMonthlyFinancialSummary({
    required this.getCustomers,
    required this.getAllPayments,
    required this.getExpenses,
    required this.getInstallations,
    required this.getPackages,
  });

  /// Returns the financial summary for the calendar month containing [month].
  /// Only the year and month fields of [month] are significant.
  Future<MonthlyFinancialSummary> call(DateTime month) async {
    final results = await Future.wait([
      getCustomers(),
      getAllPayments(),
      getExpenses(),
      getInstallations(),
      getPackages(),
    ]);

    final allCustomers = (results[0] as List).cast<dynamic>();
    final allPayments = (results[1] as List).cast<dynamic>();
    final allExpenses = (results[2] as List).cast<dynamic>();
    final allInstallations = (results[3] as List).cast<dynamic>();
    final allPackages = (results[4] as List).cast<PackageEntity>();

    final packageMap = {for (final p in allPackages) p.id: p};
    final monthKey = BillingCycle.monthKey(month);

    // ── Subscription figures ─────────────────────────────────────────────────
    // Filter to subscription type payments whose billingMonth matches.
    final monthCharges = allPayments
        .where((p) => p.isSubscription && p.billingMonth == monthKey)
        .toList();

    final subscriptionBilled =
        monthCharges.fold(0.0, (sum, p) => sum + (p.amount as double));
    final subscriptionCollected =
        monthCharges.fold(0.0, (sum, p) => sum + (p.paidAmount as double));

    // ── Subscription unpriced-customer count ─────────────────────────────────
    // Active customers whose package cost cannot be resolved.
    final activeCustomers =
        allCustomers.where((c) => c.isActive as bool).toList();
    final subscriberMargins = activeCustomers.map((c) {
      final packageId = c.packageId as String?;
      final pkg = (packageId != null && packageId.isNotEmpty)
          ? packageMap[packageId]
          : null;
      return c.monthlyMargin(pkg);
    }).toList();
    final unpricedCustomerCount =
        subscriberMargins.where((m) => !(m.isReliable as bool)).length;

    // ── Installation figures ─────────────────────────────────────────────────
    final monthInstallations = completedInMonth(
      allInstallations.cast(),
      month,
    );
    final installationMoney = installationsMoney(monthInstallations);

    // ── Expense figures ──────────────────────────────────────────────────────
    final monthExpenses = allExpenses.where((e) {
      final date = e.date as DateTime;
      return date.year == month.year && date.month == month.month;
    }).toList();

    final totalExpenses =
        monthExpenses.fold(0.0, (sum, e) => sum + (e.amount as double));

    final expensesByCategory = <ExpenseCategory, double>{};
    for (final e in monthExpenses) {
      final cat = e.category as ExpenseCategory;
      expensesByCategory[cat] = (expensesByCategory[cat] ?? 0.0) + (e.amount as double);
    }

    // ── Net profit (cash basis) ──────────────────────────────────────────────
    final netProfit =
        subscriptionCollected + installationMoney.profit - totalExpenses;

    return MonthlyFinancialSummary(
      monthKey: monthKey,
      subscriptionBilled: subscriptionBilled,
      subscriptionCollected: subscriptionCollected,
      installationRevenue: installationMoney.amountBilled,
      installationCost: installationMoney.costIncurred,
      totalExpenses: totalExpenses,
      expensesByCategory: expensesByCategory,
      netProfit: netProfit,
      unpricedCustomerCount: unpricedCustomerCount,
    );
  }
}
