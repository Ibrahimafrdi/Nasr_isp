import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/features/customers/domain/usecases/get_customers.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_all_payments.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/get_expenses.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/usecases/get_installations.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/domain/usecases/get_packages.dart';
import 'package:nasr_isp/features/reports/domain/entities/monthly_financial_summary.dart';
import 'package:nasr_isp/features/reports/domain/usecases/get_monthly_financial_summary.dart';

// Dashboard Events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardEvent extends DashboardEvent {
  const LoadDashboardEvent();
}

class RefreshDashboardEvent extends DashboardEvent {
  const RefreshDashboardEvent();
}

// Dashboard States
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardStatsModel stats;
  final List<PaymentModel> recentPayments;
  final List<PaymentModel> pendingPayments;
  final List<CustomerModel> expiringCustomers;
  final List<ExpenseModel> recentExpenses;

  // NEW chart data fields:
  final List<double> monthlyRevenue6;      // last 6 months revenue
  final List<double> customerGrowth6;      // customer count per month (last 6)
  final Map<String, int> connectionTypeDist; // {'wireless': X, 'fiber': Y}
  final Map<String, double> paymentByMethod; // {'cash': X, 'bank': Y, etc}

  const DashboardLoaded({
    required this.stats,
    required this.recentPayments,
    required this.pendingPayments,
    required this.expiringCustomers,
    required this.recentExpenses,
    required this.monthlyRevenue6,
    required this.customerGrowth6,
    required this.connectionTypeDist,
    required this.paymentByMethod,
  });

  @override
  List<Object?> get props => [
    stats,
    recentPayments,
    pendingPayments,
    expiringCustomers,
    recentExpenses,
    monthlyRevenue6,
    customerGrowth6,
    connectionTypeDist,
    paymentByMethod,
  ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetCustomers getCustomers;
  final GetAllPayments getAllPayments;
  final GetExpenses getExpenses;
  final GetInstallations getInstallations;
  final GetPackages getPackages;
  final GetMonthlyFinancialSummary getMonthlyFinancialSummary;

  /// Injectable clock so month-boundary aggregation is testable. Production
  /// uses the default; tests pass a fixed instant.
  final DateTime Function() clock;

  DashboardBloc({
    required this.getCustomers,
    required this.getAllPayments,
    required this.getExpenses,
    required this.getInstallations,
    required this.getPackages,
    required this.getMonthlyFinancialSummary,
    this.clock = DateTime.now,
  }) : super(const DashboardInitial()) {
    on<LoadDashboardEvent>(_onLoadDashboard);
    on<RefreshDashboardEvent>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboard(
    LoadDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    // Keep the current content on screen (e.g. behind a RefreshIndicator)
    // instead of flashing back to the full-screen loading spinner.
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<DashboardState> emit) async {
    try {
      final now = clock();

      // Fetch all data in parallel. Payments and installations are fetched
      // unbounded (no limit) so aggregate stats never silently drop older
      // records once a collection grows past an arbitrary page size.
      final results = await Future.wait([
        getCustomers(),
        getAllPayments(),
        getExpenses(),
        getInstallations(),
        getPackages(),
        getMonthlyFinancialSummary(now),
      ]);

      final allCustomers = (results[0] as List).cast<CustomerModel>();
      final allPayments = (results[1] as List).cast<PaymentModel>();
      final allExpenses = (results[2] as List).cast<ExpenseModel>();
      final allInstallations = (results[3] as List).cast<InstallationEntity>();
      final allPackages = (results[4] as List).cast<PackageEntity>();
      final monthlySummary = results[5] as MonthlyFinancialSummary;

      final packageMap = {for (final p in allPackages) p.id: p};

      // Customer stats
      final totalCustomers = allCustomers.length;
      final activeList =
          allCustomers.where((c) => c.isActive).toList();
      final activeCustomers = activeList.length;
      // Expired/expiring-soon only make sense for customers still on an
      // active subscription — a cancelled customer with a stale due date
      // shouldn't surface as a renewal to chase. Both predicates live on
      // CustomerEntity so this page, the customers list and the Renew button
      // can never disagree about who has lapsed.
      final expiredList = activeList.where((c) => c.isExpiredAt(now)).toList();
      final expiredCustomers = expiredList.length;
      final expiringSoon = activeList.where((c) {
        final due = c.effectiveDueDate;
        if (due == null) return false;
        final days = BillingCycle.daysUntilDue(due, now);
        return days >= 0 && days <= BillingCycle.renewalWindowDays;
      }).toList();

      // Payment stats. Payment status is normalized to just
      // 'paid' / 'unpaid' / 'partial' by PaymentRemoteDataSourceImpl before it
      // ever reaches this bloc.
      //
      // NOTE: `payments` holds SUBSCRIPTION billing only. Installation setup
      // fees and materials are billed to the customer but never written to
      // this collection, so every cash figure derived here is subscription
      // cash. PaymentType.subscription is filtered on explicitly rather than
      // assumed, so that folding installations into the ledger later cannot
      // silently contaminate these aggregates.
      final subscriptionPayments =
          allPayments.where((p) => p.isSubscription).toList();

      // CASH BASIS — bucketed by when the money arrived.
      final cashCollectedThisMonth = subscriptionPayments
          .where((p) {
            if (p.status != 'paid') return false;
            final date = p.completedDate ?? p.createdAt;
            return date != null &&
                date.year == now.year &&
                date.month == now.month;
          })
          .fold(0.0, (total, p) => total + p.paidAmount);

      // CURRENT BILLING MONTH — bucketed by the period the charge covers, so
      // these reconcile against the accrual run rate below.
      final currentMonthKey = BillingCycle.monthKey(now);
      final currentMonthCharges = subscriptionPayments
          .where((p) => p.billingMonth == currentMonthKey)
          .toList();

      final currentMonthOutstanding =
          currentMonthCharges.fold(0.0, (total, p) => total + p.remainingAmount);

      // Realized margin. Charges written before the cost snapshot existed fall
      // back to the customer's currently-resolved package cost — without that
      // fallback every legacy row would report as 100% margin and the
      // reconciliation against the run rate would be meaningless.
      final customerById = {for (final c in allCustomers) c.id: c};
      double liveCostFor(String customerId) {
        final customer = customerById[customerId];
        final packageId = customer?.packageId;
        if (packageId == null || packageId.isEmpty) return 0.0;
        return packageMap[packageId]?.costPrice ?? 0.0;
      }

      final currentMonthMarginCollected = currentMonthCharges.fold<double>(
        0.0,
        (sum, p) =>
            sum +
            p.collectedMargin(fallbackCost: liveCostFor(p.customerId)).profit,
      );

      // Lapsed customers with no charge for this month at all — the renewals
      // that have not been started. Disjoint from currentMonthOutstanding,
      // which only covers customers who HAVE been renewed this month, so the
      // two sum without double counting.
      final billedThisMonth =
          currentMonthCharges.map((p) => p.customerId).toSet();
      final unbilledExpired = expiredList
          .where((c) => !billedThisMonth.contains(c.id))
          .toList();
      final expiredCustomersDue =
          unbilledExpired.fold(0.0, (total, c) => total + c.monthlyBill);

      // Pending payments (used for both the KPI total and the overdue list) —
      // all-time arrears, not just this month.
      final pendingPayments = subscriptionPayments
          .where((p) => p.status == 'unpaid' || p.status == 'partial')
          .toList()
        ..sort((a, b) {
          final aDate = a.dueDate ?? DateTime(2000);
          final bDate = b.dueDate ?? DateTime(2000);
          return aDate.compareTo(bDate);
        });

      final pendingPaymentsAmount = pendingPayments
          .fold(0.0, (sum, p) => sum + p.remainingAmount);

      // ACCRUAL RUN RATE for active subscribers:
      // margin per customer = customer.monthlyBill - package.costPrice.
      // A full-month figure, independent of who has actually paid, and the
      // yardstick currentMonthMarginCollected converges on as renewals come in.
      final subscriberMargins = activeList
          .map((c) => c.monthlyMargin(
                (c.packageId != null && c.packageId!.isNotEmpty)
                    ? packageMap[c.packageId]
                    : null,
              ))
          .toList();

      final subscriberRunRateMargin =
          subscriberMargins.fold<double>(0.0, (sum, m) => sum + m.money.profit);

      // Installation stats
      final pendingInstallations = allInstallations
          .where((i) =>
              i.status == InstallationStatus.pending ||
              i.status == InstallationStatus.inProgress)
          .length;
      final completedInstallations = allInstallations
          .where((i) => i.status == InstallationStatus.completed)
          .length;

      // ACCRUAL BASIS — these three terms are the three adjacent KPI cards.
      // Cash collected is deliberately excluded: different basis, and it does
      // not include installation billing at all.
      final netProfit = subscriberRunRateMargin +
          monthlySummary.installationProfit -
          monthlySummary.totalExpenses;

      final stats = DashboardStatsModel(
        totalCustomers: totalCustomers,
        activeCustomers: activeCustomers,
        expiredCustomers: expiredCustomers,
        expiringsoon: expiringSoon.length,
        subscriberRunRateMargin: subscriberRunRateMargin,
        cashCollectedThisMonth: cashCollectedThisMonth,
        monthlyExpenses: monthlySummary.totalExpenses,
        netProfit: netProfit,
        pendingPayments: pendingPaymentsAmount,
        pendingPaymentsCount: pendingPayments.length,
        pendingInstallations: pendingInstallations,
        completedInstallations: completedInstallations,
        monthlyInstallationRevenue: monthlySummary.installationRevenue,
        monthlyInstallationCost: monthlySummary.installationCost,
        monthlyInstallationProfit: monthlySummary.installationProfit,
        unpricedCustomerCount: monthlySummary.unpricedCustomerCount,
        currentMonthBilled: monthlySummary.subscriptionBilled,
        currentMonthCollected: monthlySummary.subscriptionCollected,
        currentMonthMarginCollected: currentMonthMarginCollected,
        currentMonthOutstanding: currentMonthOutstanding,
        expiredCustomersDue: expiredCustomersDue,
        expiredCustomersDueCount: unbilledExpired.length,
      );

      // Recent payments (last 5 paid)
      final recentPayments = allPayments
          .where((p) => p.status == 'paid')
          .toList()
        ..sort((a, b) {
          final aDate = a.completedDate ?? a.createdAt ?? DateTime(2000);
          final bDate = b.completedDate ?? b.createdAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });

      // Recent expenses (last 5)
      final recentExpenses = List<ExpenseModel>.from(allExpenses)
        ..sort((a, b) => b.date.compareTo(a.date));

      // ── Monthly Revenue (last 6 months) ─────────────────
      // Build a list of 6 doubles: index 0 = 6 months ago, index 5 = current month
      final List<double> monthlyRevenue6 = List.filled(6, 0.0);
      for (final p in allPayments) {
        if (p.status != 'paid') continue;
        final date = p.completedDate ?? p.createdAt;
        if (date == null) continue;
        for (int i = 0; i < 6; i++) {
          final target = DateTime(now.year, now.month - (5 - i));
          if (date.year == target.year && date.month == target.month) {
            monthlyRevenue6[i] += p.paidAmount;
            break;
          }
        }
      }

      // ── Customer Growth (last 6 months) ─────────────────
      // Count customers whose createdAt <= end of that month (cumulative)
      final List<double> customerGrowth6 = List.filled(6, 0.0);
      for (int i = 0; i < 6; i++) {
        final target = DateTime(now.year, now.month - (5 - i));
        final endOfMonth = DateTime(target.year, target.month + 1, 0);
        customerGrowth6[i] = allCustomers
            .where((c) =>
                c.createdAt != null && c.createdAt!.isBefore(endOfMonth))
            .length
            .toDouble();
      }

      // ── Connection Type Distribution ─────────────────────
      final Map<String, int> connectionTypeDist = {
        'wireless': allCustomers
            .where((c) => c.connectionType == 'wireless').length,
        'fiber': allCustomers
            .where((c) => c.connectionType == 'fiber').length,
      };

      // ── Payment by Method (paid payments only) ──────
      final Map<String, double> paymentByMethod = {};
      for (final p in allPayments) {
        if (p.status != 'paid') continue;
        final method = (p.method ?? 'other').toLowerCase().trim();
        paymentByMethod[method] =
            (paymentByMethod[method] ?? 0) + p.paidAmount;
      }

      emit(DashboardLoaded(
        stats: stats,
        recentPayments: recentPayments.take(5).toList(),
        pendingPayments: pendingPayments.take(5).toList(),
        expiringCustomers: expiringSoon.take(10).toList(),
        recentExpenses: recentExpenses.take(5).toList(),
        monthlyRevenue6: monthlyRevenue6,
        customerGrowth6: customerGrowth6,
        connectionTypeDist: connectionTypeDist,
        paymentByMethod: paymentByMethod,
      ));
    } catch (e) {
      emit(DashboardError(message: 'Failed to load dashboard: $e'));
    }
  }
}
