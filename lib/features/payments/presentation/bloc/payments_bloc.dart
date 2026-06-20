import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/shared/models/models.dart';

// ──────────────────────────────────────────────
// Events
// ──────────────────────────────────────────────

abstract class PaymentsEvent extends Equatable {
  const PaymentsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPaymentsEvent extends PaymentsEvent {
  final int page;
  final String? searchQuery;
  final PaymentStatus? filterStatus;
  final List<String>? filterStatuses;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;

  const LoadPaymentsEvent({
    this.page = 1,
    this.searchQuery,
    this.filterStatus,
    this.filterStatuses,
    this.dateRangeStart,
    this.dateRangeEnd,
  });

  @override
  List<Object?> get props => [
    page,
    searchQuery,
    filterStatus,
    filterStatuses,
    dateRangeStart,
    dateRangeEnd,
  ];
}

// ──────────────────────────────────────────────
// States
// ──────────────────────────────────────────────

abstract class PaymentsState extends Equatable {
  const PaymentsState();

  @override
  List<Object?> get props => [];
}

class PaymentsInitial extends PaymentsState {
  const PaymentsInitial();
}

class PaymentsLoading extends PaymentsState {
  const PaymentsLoading();
}

class PaymentsLoaded extends PaymentsState {
  final List<PaymentModel> payments;
  final int currentPage;
  final int totalPages;
  final double totalAmount;
  final double collectedAmount;

  const PaymentsLoaded({
    required this.payments,
    required this.currentPage,
    required this.totalPages,
    required this.totalAmount,
    required this.collectedAmount,
  });

  @override
  List<Object?> get props => [
    payments,
    currentPage,
    totalPages,
    totalAmount,
    collectedAmount,
  ];
}

class PaymentsError extends PaymentsState {
  final String message;

  const PaymentsError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ──────────────────────────────────────────────
// BLoC
// ──────────────────────────────────────────────

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  PaymentsBloc() : super(const PaymentsInitial()) {
    on<LoadPaymentsEvent>(_onLoadPayments);
  }

  Future<void> _onLoadPayments(
    LoadPaymentsEvent event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(const PaymentsLoading());

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      var payments = _generateMockPayments();

      // Apply search filter
      final query = event.searchQuery?.trim().toLowerCase();
      if (query != null && query.isNotEmpty) {
        payments = payments
            .where((p) => p.customerName.toLowerCase().contains(query))
            .toList();
      }

      // ✅ FIX: Apply multi-status filter (this is what the UI chips actually send)
      if (event.filterStatuses != null && event.filterStatuses!.isNotEmpty) {
        payments = payments
            .where((p) => event.filterStatuses!.contains(p.status.label))
            .toList();
      }

      // Keep single-status filter too, in case it's used elsewhere
      if (event.filterStatus != null) {
        payments = payments
            .where((p) => p.status == event.filterStatus)
            .toList();
      }

      // Compute totals on the full filtered list (not just the current page)
      final totalAmount = payments.fold<double>(0, (sum, p) => sum + p.amount);
      final collectedAmount = payments.fold<double>(
        0,
        (sum, p) => sum + p.paidAmount,
      );

      // Paginate
      final itemsPerPage = AppConstants.itemsPerPage;
      final totalPages = payments.isEmpty
          ? 1
          : (payments.length / itemsPerPage).ceil();

      // Clamp page to valid range
      final page = event.page.clamp(1, totalPages);
      final start = (page - 1) * itemsPerPage;
      final end = (start + itemsPerPage).clamp(0, payments.length);
      final paginated = payments.sublist(start, end);

      emit(
        PaymentsLoaded(
          payments: paginated,
          currentPage: page,
          totalPages: totalPages,
          totalAmount: totalAmount,
          collectedAmount: collectedAmount,
        ),
      );
    } catch (e) {
      emit(PaymentsError(message: 'Failed to load payments: $e'));
    }
  }

  // ── Mock data helper ───────────────────────

  List<PaymentModel> _generateMockPayments() {
    final baseDate = DateTime.now();
    const statuses = [
      PaymentStatus.completed,
      PaymentStatus.pending,
      PaymentStatus.partial,
      PaymentStatus.failed,
    ];

    return List.generate(80, (i) {
      return PaymentModel(
        id: 'pay_$i',
        customerId: 'cust_${i % 30}',
        customerName: 'Customer ${i % 30 + 1}',
        amount: 1500,
        paidAmount: i % 3 == 0 ? 0 : (i % 3 == 1 ? 750 : 1500),
        status: statuses[i % statuses.length],
        dueDate: baseDate.subtract(Duration(days: 30 - (i % 30))),
        completedDate: i % 2 == 0
            ? baseDate.subtract(Duration(days: 20 - (i % 20)))
            : null,
        method: i % 2 == 0 ? 'Bank Transfer' : 'Cash',
        notes: 'Monthly subscription payment',
        createdAt: baseDate.subtract(Duration(days: 40 - (i % 40))),
      );
    });
  }
}
