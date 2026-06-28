import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/features/customers/domain/usecases/get_customers.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_payments.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/get_expenses.dart';

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
  final GetPayments getPayments;
  final GetExpenses getExpenses;

  DashboardBloc({
    required this.getCustomers,
    required this.getPayments,
    required this.getExpenses,
  }) : super(const DashboardInitial()) {
    on<LoadDashboardEvent>(_onLoadDashboard);
    on<RefreshDashboardEvent>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboard(
    LoadDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        getCustomers(),
        getPayments(),
        getExpenses(),
      ]);

      final allCustomers = (results[0] as List).cast<CustomerModel>();
      final allPayments = (results[1] as List).cast<PaymentModel>();
      final allExpenses = (results[2] as List).cast<ExpenseModel>();

      final now = DateTime.now();

      // Customer stats
      final totalCustomers = allCustomers.length;
      final activeCustomers = allCustomers
          .where((c) => c.status == 'active').length;
      final expiredCustomers = allCustomers
          .where((c) {
            final due = c.nextDueDate ??
                (c.createdAt != null
                    ? DateTime(c.createdAt!.year,
                        c.createdAt!.month + 1, c.createdAt!.day)
                    : null);
            return due != null && due.isBefore(now);
          }).length;
      final expiringSoon = allCustomers.where((c) {
        final due = c.nextDueDate ??
            (c.createdAt != null
                ? DateTime(c.createdAt!.year,
                    c.createdAt!.month + 1, c.createdAt!.day)
                : null);
        if (due == null) return false;
        final diff = due.difference(now).inDays;
        return diff >= 0 && diff <= 7;
      }).toList();

      // Payment stats — current month only
      final currentMonthPayments = allPayments.where((p) {
        final date = p.completedDate ?? p.createdAt;
        if (date == null) return false;
        return date.year == now.year && date.month == now.month;
      }).toList();

      final monthlyRevenue = currentMonthPayments
          .where((p) => p.status == 'completed')
          .fold(0.0, (sum, p) => sum + p.paidAmount);

      final pendingPaymentsAmount = allPayments
          .where((p) => p.status == 'pending' || p.status == 'partial')
          .fold(0.0, (sum, p) => sum + p.amount);

      // Expense stats — current month only
      final currentMonthExpenses = allExpenses.where((e) {
        return e.date.year == now.year && e.date.month == now.month;
      }).toList();

      final monthlyExpenses = currentMonthExpenses
          .fold(0.0, (sum, e) => sum + e.amount);

      final netProfit = monthlyRevenue - monthlyExpenses;

      final stats = DashboardStatsModel(
        totalCustomers: totalCustomers,
        activeCustomers: activeCustomers,
        expiredCustomers: expiredCustomers,
        expiringsoon: expiringSoon.length,
        monthlyRevenue: monthlyRevenue,
        monthlyExpenses: monthlyExpenses,
        netProfit: netProfit,
        pendingPayments: pendingPaymentsAmount,
      );

      // Recent payments (last 5 completed)
      final recentPayments = allPayments
          .where((p) => p.status == 'completed')
          .toList()
        ..sort((a, b) {
          final aDate = a.completedDate ?? a.createdAt ?? DateTime(2000);
          final bDate = b.completedDate ?? b.createdAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });

      // Pending payments
      final pendingPayments = allPayments
          .where((p) => p.status == 'pending' || p.status == 'partial')
          .toList()
        ..sort((a, b) {
          final aDate = a.dueDate ?? DateTime(2000);
          final bDate = b.dueDate ?? DateTime(2000);
          return aDate.compareTo(bDate);
        });

      // Recent expenses (last 5)
      final recentExpenses = List<ExpenseModel>.from(allExpenses)
        ..sort((a, b) => b.date.compareTo(a.date));

      // ── Monthly Revenue (last 6 months) ─────────────────
      // Build a list of 6 doubles: index 0 = 6 months ago, index 5 = current month
      final List<double> monthlyRevenue6 = List.filled(6, 0.0);
      for (final p in allPayments) {
        if (p.status != 'completed') continue;
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

      // ── Payment by Method (completed payments only) ──────
      final Map<String, double> paymentByMethod = {};
      for (final p in allPayments) {
        if (p.status != 'completed') continue;
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

  Future<void> _onRefreshDashboard(
    RefreshDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    await _onLoadDashboard(const LoadDashboardEvent(), emit);
  }
}
