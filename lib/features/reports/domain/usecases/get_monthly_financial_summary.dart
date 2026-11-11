import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/customers/domain/usecases/get_customers.dart';
import 'package:nasr_isp/features/expenses/domain/entities/expense_entity.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/get_expenses.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/usecases/get_installations.dart';
import 'package:nasr_isp/features/installations/domain/utils/installation_aggregates.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_issue_entity.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/get_stock_issues.dart';
import 'package:nasr_isp/features/inventory/domain/utils/stock_sales_aggregates.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/domain/usecases/get_packages.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_all_payments.dart';
import 'package:nasr_isp/features/reports/domain/entities/monthly_financial_summary.dart';

/// Computes a [MonthlyFinancialSummary] for any given calendar month.
///
/// Reuses [MoneyLine], [BillingCycle], [completedInMonth],
/// [installationsMoney], and [stockSalesTotals] exactly as [DashboardBloc] does —
/// no math is reimplemented, only parameterised.
///
/// All six repository reads are performed here so the usecase is self-
/// contained and testable in isolation. Callers that have already fetched the
/// domain collections (such as [DashboardBloc]) can pass them directly to
/// avoid duplicate network reads.
class GetMonthlyFinancialSummary {
  final GetCustomers getCustomers;
  final GetAllPayments getAllPayments;
  final GetExpenses getExpenses;
  final GetInstallations getInstallations;
  final GetPackages getPackages;
  final GetStockIssues getStockIssues;

  const GetMonthlyFinancialSummary({
    required this.getCustomers,
    required this.getAllPayments,
    required this.getExpenses,
    required this.getInstallations,
    required this.getPackages,
    required this.getStockIssues,
  });

  /// Returns the financial summary for the calendar month containing [month].
  /// Only the year and month fields of [month] are significant.
  /// If collections are provided via optional arguments, they are used directly
  /// instead of fetching from repositories.
  Future<MonthlyFinancialSummary> call(
    DateTime month, {
    List<CustomerEntity>? customers,
    List<PaymentEntity>? payments,
    List<ExpenseEntity>? expenses,
    List<InstallationEntity>? installations,
    List<PackageEntity>? packages,
    List<StockIssueEntity>? stockIssues,
  }) async {
    final List<CustomerEntity> allCustomers;
    final List<PaymentEntity> allPayments;
    final List<ExpenseEntity> allExpenses;
    final List<InstallationEntity> allInstallations;
    final List<PackageEntity> allPackages;
    final List<StockIssueEntity> allStockIssues;

    if (customers != null &&
        payments != null &&
        expenses != null &&
        installations != null &&
        packages != null &&
        stockIssues != null) {
      allCustomers = customers;
      allPayments = payments;
      allExpenses = expenses;
      allInstallations = installations;
      allPackages = packages;
      allStockIssues = stockIssues;
    } else {
      // Bound the payments fetch to the target billing month only — this
      // usecase only ever filters to that month (see monthKey filter below),
      // so fetching the full all-time history here is wasteful.
      final monthStart = DateTime(month.year, month.month, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 0); // last day
      final nextMonthStart = DateTime(month.year, month.month + 1, 1);

      final results = await Future.wait([
        customers != null ? Future.value(customers) : getCustomers(),
        payments != null
            ? Future.value(payments)
            : getAllPayments(startDate: monthStart, endDate: monthEnd),
        expenses != null ? Future.value(expenses) : getExpenses(),
        installations != null ? Future.value(installations) : getInstallations(),
        packages != null ? Future.value(packages) : getPackages(),
        stockIssues != null
            ? Future.value(stockIssues)
            : getStockIssues(startDate: monthStart, endDate: nextMonthStart),
      ]);

      allCustomers = results[0] as List<CustomerEntity>;
      allPayments = results[1] as List<PaymentEntity>;
      allExpenses = results[2] as List<ExpenseEntity>;
      allInstallations = results[3] as List<InstallationEntity>;
      allPackages = results[4] as List<PackageEntity>;
      allStockIssues = results[5] as List<StockIssueEntity>;
    }

    final packageMap = {for (final p in allPackages) p.id: p};
    final monthKey = BillingCycle.monthKey(month);

    // ── Subscription figures ─────────────────────────────────────────────────
    // Filter to subscription type payments whose billingMonth matches.
    final monthCharges = allPayments
        .where((p) => p.isSubscription && p.billingMonth == monthKey)
        .toList();

    final subscriptionBilled =
        monthCharges.fold(0.0, (sum, p) => sum + p.amount);
    final subscriptionCollected =
        monthCharges.fold(0.0, (sum, p) => sum + p.paidAmount);

    // ── Subscription unpriced-customer count ─────────────────────────────────
    // Active customers whose package cost cannot be resolved.
    final activeCustomers =
        allCustomers.where((c) => c.isActive).toList();
    final subscriberMargins = activeCustomers.map((c) {
      final packageId = c.packageId;
      final pkg = (packageId != null && packageId.isNotEmpty)
          ? packageMap[packageId]
          : null;
      return c.monthlyMargin(pkg);
    }).toList();
    final unpricedCustomerCount =
        subscriberMargins.where((m) => !m.isReliable).length;

    // ── Installation figures ─────────────────────────────────────────────────
    final monthInstallations = completedInMonth(
      allInstallations.cast(),
      month,
    );
    final installationMoney = installationsMoney(monthInstallations);

    // ── Product Sales figures ────────────────────────────────────────────────
    final monthSales = salesInMonth(allStockIssues, month);
    final productSales = stockSalesTotals(monthSales);

    // ── Expense figures ──────────────────────────────────────────────────────
    final monthExpenses = allExpenses.where((e) {
      final date = e.date;
      return date.year == month.year && date.month == month.month;
    }).toList();

    final totalExpenses =
        monthExpenses.fold(0.0, (sum, e) => sum + e.amount);

    final expensesByCategory = <ExpenseCategory, double>{};
    for (final e in monthExpenses) {
      final cat = e.category;
      expensesByCategory[cat] = (expensesByCategory[cat] ?? 0.0) + e.amount;
    }

    // ── Net profit (cash basis) ──────────────────────────────────────────────
    final netProfit =
        subscriptionCollected +
        installationMoney.profit +
        productSales.profit -
        totalExpenses;

    return MonthlyFinancialSummary(
      monthKey: monthKey,
      subscriptionBilled: subscriptionBilled,
      subscriptionCollected: subscriptionCollected,
      installationRevenue: installationMoney.amountBilled,
      installationCost: installationMoney.costIncurred,
      productSalesRevenue: productSales.revenue,
      productSalesCost: productSales.cost,
      productSalesCount: productSales.salesCount,
      productSalesUnits: productSales.unitsSold,
      totalExpenses: totalExpenses,
      expensesByCategory: expensesByCategory,
      netProfit: netProfit,
      unpricedCustomerCount: unpricedCustomerCount,
    );
  }
}
