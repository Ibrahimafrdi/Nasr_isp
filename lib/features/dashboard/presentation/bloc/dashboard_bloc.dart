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
import 'package:nasr_isp/features/installations/domain/utils/installation_aggregates.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/domain/usecases/get_packages.dart';

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

  /// Injectable clock so month-boundary aggregation is testable. Production
  /// uses the default; tests pass a fixed instant.
  final DateTime Function() clock;

  DashboardBloc({
    required this.getCustomers,
    required this.getAllPayments,
    required this.getExpenses,
    required this.getInstallations,
    required this.getPackages,
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
      // Fetch all data in parallel. Payments and installations are fetched
      // unbounded (no limit) so aggregate stats never silently drop older
      // records once a collection grows past an arbitrary page size.
      final results = await Future.wait([
        getCustomers(),
        getAllPayments(),
        getExpenses(),
        getInstallations(),
        getPackages(),
      ]);

      final allCustomers = (results[0] as List).cast<CustomerModel>();
      final allPayments = (results[1] as List).cast<PaymentModel>();
      final allExpenses = (results[2] as List).cast<ExpenseModel>();
      final allInstallations = (results[3] as List).cast<InstallationEntity>();
      final allPackages = (results[4] as List).cast<PackageEntity>();

      final packageMap = {for (final p in allPackages) p.id: p};

      final now = clock();

      // Customer stats
      final totalCustomers = allCustomers.length;
      final activeCustomers = allCustomers
          .where((c) => c.status == 'active').length;
      // Expired/expiring-soon only make sense for customers still on an
      // active subscription — a cancelled customer with a stale due date
      // shouldn't surface as a renewal to chase.
      final expiredCustomers = allCustomers
          .where((c) {
            if (c.status != 'active') return false;
            final due = c.nextDueDate ??
                (c.createdAt != null
                    ? DateTime(c.createdAt!.year,
                        c.createdAt!.month + 1, c.createdAt!.day)
                    : null);
            return due != null && due.isBefore(now);
          }).length;
      final expiringSoon = allCustomers.where((c) {
        if (c.status != 'active') return false;
        final due = c.nextDueDate ??
            (c.createdAt != null
                ? DateTime(c.createdAt!.year,
                    c.createdAt!.month + 1, c.createdAt!.day)
                : null);
        if (due == null) return false;
        final diff = due.difference(now).inDays;
        return diff >= 0 && diff <= 7;
      }).toList();

      // Payment stats — current month only.
      // Payment status is normalized to just 'paid' / 'unpaid' / 'partial'
      // by PaymentRemoteDataSourceImpl before it ever reaches this bloc.
      //
      // NOTE: `payments` holds SUBSCRIPTION billing only. Installation setup
      // fees and materials are billed to the customer but never written to
      // this collection, and PaymentEntity has no type discriminator. Any
      // "cash collected" figure derived here is therefore subscription cash
      // only — label it as such, and do not fold installations into it
      // without the PaymentEntity.type work first.
      final currentMonthPayments = allPayments.where((p) {
        final date = p.completedDate ?? p.createdAt;
        if (date == null) return false;
        return date.year == now.year && date.month == now.month;
      }).toList();

      final cashCollectedThisMonth = currentMonthPayments
          .where((p) => p.status == 'paid')
          .fold(0.0, (sum, p) => sum + p.paidAmount);

      // Pending payments (used for both the KPI total and the overdue list)
      final pendingPayments = allPayments
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
      // A full-month figure, independent of who has actually paid.
      final subscriberMargins = allCustomers
          .where((c) => c.status == 'active')
          .map((c) => c.monthlyMargin(
                (c.packageId != null && c.packageId!.isNotEmpty)
                    ? packageMap[c.packageId]
                    : null,
              ))
          .toList();

      final subscriberRunRateMargin =
          MoneyLine.sum(subscriberMargins.map((m) => m.money)).profit;
      // Customers with no usable package cost — no package assigned, or a
      // packageId that no longer resolves — fall back to a zero cost price, so
      // their whole bill counts as margin and the run rate above is an upper
      // bound whenever this is non-zero.
      final unpricedCustomerCount =
          subscriberMargins.where((m) => !m.isReliable).length;

      // Expense stats — current month only
      final currentMonthExpenses = allExpenses.where((e) {
        return e.date.year == now.year && e.date.month == now.month;
      }).toList();

      final monthlyExpenses = currentMonthExpenses
          .fold(0.0, (sum, e) => sum + e.amount);

      // Installation stats
      final pendingInstallations = allInstallations
          .where((i) =>
              i.status == InstallationStatus.pending ||
              i.status == InstallationStatus.inProgress)
          .length;
      final completedInstallations = allInstallations
          .where((i) => i.status == InstallationStatus.completed)
          .length;

      // Installation financials.
      // SCOPE: completed jobs only — cancelled and pending never contribute
      // money — bucketed into the current calendar month by completedAt,
      // falling back to createdAt for legacy docs.
      final currentMonthCompletedInstallations =
          completedInMonth(allInstallations, now);

      // All three figures come off one MoneyLine, so revenue - cost == profit
      // holds by construction rather than by coincidence. Revenue is what the
      // customer was billed: setup fee PLUS materials at sell price.
      final installationMoney =
          installationsMoney(currentMonthCompletedInstallations);
      final monthlyInstallationRevenue = installationMoney.amountBilled;
      final monthlyInstallationCost = installationMoney.costIncurred;
      final monthlyInstallationProfit = installationMoney.profit;

      // ACCRUAL BASIS — these three terms are the three adjacent KPI cards.
      // Cash collected is deliberately excluded: different basis, and it does
      // not include installation billing at all.
      final netProfit = subscriberRunRateMargin +
          monthlyInstallationProfit -
          monthlyExpenses;

      final stats = DashboardStatsModel(
        totalCustomers: totalCustomers,
        activeCustomers: activeCustomers,
        expiredCustomers: expiredCustomers,
        expiringsoon: expiringSoon.length,
        subscriberRunRateMargin: subscriberRunRateMargin,
        cashCollectedThisMonth: cashCollectedThisMonth,
        monthlyExpenses: monthlyExpenses,
        netProfit: netProfit,
        pendingPayments: pendingPaymentsAmount,
        pendingPaymentsCount: pendingPayments.length,
        pendingInstallations: pendingInstallations,
        completedInstallations: completedInstallations,
        monthlyInstallationRevenue: monthlyInstallationRevenue,
        monthlyInstallationCost: monthlyInstallationCost,
        monthlyInstallationProfit: monthlyInstallationProfit,
        unpricedCustomerCount: unpricedCustomerCount,
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
