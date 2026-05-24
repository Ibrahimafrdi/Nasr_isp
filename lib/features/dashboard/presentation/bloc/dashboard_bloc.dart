import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/shared/models/models.dart';

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

  const DashboardLoaded({
    required this.stats,
    required this.recentPayments,
    required this.pendingPayments,
    required this.expiringCustomers,
    required this.recentExpenses,
  });

  @override
  List<Object?> get props => [
    stats,
    recentPayments,
    pendingPayments,
    expiringCustomers,
    recentExpenses,
  ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Dashboard BLoC
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(const DashboardInitial()) {
    on<LoadDashboardEvent>(_onLoadDashboard);
    on<RefreshDashboardEvent>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboard(
    LoadDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    await Future.delayed(const Duration(seconds: 1));

    try {
      // FIX: generate once, reuse — avoids calling generators twice
      final allPayments = _generateMockPayments();
      final allCustomers = _generateMockCustomers();

      final stats = _generateMockStats();
      final recentPayments = allPayments.take(5).toList();
      final pendingPayments = allPayments
          .where((p) => p.status == PaymentStatus.pending)
          .take(5)
          .toList();
      final expiringCustomers = allCustomers
          .where((c) => c.status == CustomerStatus.expiringSoon)
          .take(10)
          .toList();
      final recentExpenses = _generateMockExpenses().take(5).toList();

      emit(
        DashboardLoaded(
          stats: stats,
          recentPayments: recentPayments,
          pendingPayments: pendingPayments,
          expiringCustomers: expiringCustomers,
          recentExpenses: recentExpenses,
        ),
      );
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

  DashboardStatsModel _generateMockStats() {
    return const DashboardStatsModel(
      totalCustomers: 284,
      activeCustomers: 256,
      expiredCustomers: 12,
      expiringsoon: 16,
      monthlyRevenue: 285000,
      monthlyExpenses: 125000,
      netProfit: 160000,
      pendingPayments: 45000,
    );
  }

  List<CustomerModel> _generateMockCustomers() {
    final baseDate = DateTime.now();
    return List.generate(50, (i) {
      final daysUntilExpiry = 7 + (i % 30);
      final expiryDate = baseDate.add(Duration(days: daysUntilExpiry));

      CustomerStatus status;
      if (daysUntilExpiry <= 0) {
        status = CustomerStatus.expired;
      } else if (daysUntilExpiry <= 7) {
        status = CustomerStatus.expiringSoon;
      } else {
        status = CustomerStatus.active;
      }

      return CustomerModel(
        id: 'cust_$i',
        name: 'Customer ${i + 1}',
        phone: '+923001234${500 + i}',
        address: 'Address $i, Karachi',
        email: 'customer$i@email.com',
        packageName: ['10 Mbps', '25 Mbps', '50 Mbps'][i % 3],
        monthlyRate: [999, 1499, 2499][i % 3].toDouble(),
        expiryDate: expiryDate,
        status: status,
        assignedEmployeeId: 'emp_${i % 5}',
        createdAt: baseDate.subtract(Duration(days: 90 + i)),
        balance: (i % 2 == 0) ? 0 : (500 + (i * 100)).toDouble(),
      );
    });
  }

  List<PaymentModel> _generateMockPayments() {
    final baseDate = DateTime.now();
    final statuses = [
      PaymentStatus.completed,
      PaymentStatus.pending,
      PaymentStatus.partial,
      PaymentStatus.failed,
    ];

    return List.generate(30, (i) {
      return PaymentModel(
        id: 'pay_$i',
        customerId: 'cust_${i % 10}',
        customerName: 'Customer ${i % 10 + 1}',
        amount: 1500,
        paidAmount: i % 3 == 0 ? 0 : (i % 3 == 1 ? 750 : 1500),
        status: statuses[i % statuses.length],
        dueDate: baseDate.subtract(Duration(days: 30 - i)),
        completedDate: i % 2 == 0
            ? baseDate.subtract(Duration(days: 20 - i))
            : null,
        method: i % 2 == 0 ? 'Bank Transfer' : 'Cash',
        notes: 'Monthly subscription payment',
        createdAt: baseDate.subtract(Duration(days: 40 - i)),
      );
    });
  }

  List<ExpenseModel> _generateMockExpenses() {
    final baseDate = DateTime.now();
    final categories = ExpenseCategory.values;
    return List.generate(20, (i) {
      return ExpenseModel(
        id: 'exp_$i',
        description: 'Expense ${i + 1}',
        category: categories[i % categories.length],
        amount: (5000 + (i * 1000)).toDouble(),
        date: baseDate.subtract(Duration(days: i)),
        notes: 'Sample note for expense',
        createdAt: baseDate.subtract(Duration(days: i)),
      );
    });
  }
}
