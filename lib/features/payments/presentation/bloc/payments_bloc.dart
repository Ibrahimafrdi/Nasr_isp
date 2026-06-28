import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/features/customers/domain/usecases/get_customers.dart';
import 'package:nasr_isp/features/customers/domain/usecases/update_customer.dart';

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
  final String? filterStatus;
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

class CreatePaymentEvent extends PaymentsEvent {
  final PaymentModel payment;

  const CreatePaymentEvent(this.payment);

  @override
  List<Object?> get props => [payment];
}

class UpdatePaymentEvent extends PaymentsEvent {
  final PaymentModel payment;

  const UpdatePaymentEvent(this.payment);

  @override
  List<Object?> get props => [payment];
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
  final GetCustomers getCustomers;
  final UpdateCustomer updateCustomer;
  
  // In-memory list to accumulate created or updated payments during this session
  final List<PaymentModel> _createdPayments = [];

  PaymentsBloc({
    required this.getCustomers,
    required this.updateCustomer,
  }) : super(const PaymentsInitial()) {
    on<LoadPaymentsEvent>(_onLoadPayments);
    on<CreatePaymentEvent>(_onCreatePayment);
    on<UpdatePaymentEvent>(_onUpdatePayment);
  }

  Future<void> _onCreatePayment(
    CreatePaymentEvent event,
    Emitter<PaymentsState> emit,
  ) async {
    // Persist created payment in memory for this session
    _createdPayments.add(event.payment);
    // Reload with the new payment included
    await _onLoadPayments(const LoadPaymentsEvent(), emit);
  }

  Future<void> _onUpdatePayment(
    UpdatePaymentEvent event,
    Emitter<PaymentsState> emit,
  ) async {
    final updatedPayment = event.payment;

    if (updatedPayment.status == 'paid' && updatedPayment.completedDate != null) {
      final newNextDueDate = DateTime(
        updatedPayment.completedDate!.year,
        updatedPayment.completedDate!.month + 1,
        updatedPayment.completedDate!.day,
      );

      try {
        // Load existing customer and update nextDueDate
        final customers = await getCustomers();
        final customer = customers.firstWhere((c) => c.id == updatedPayment.customerId);
        final updatedCustomer = (customer as CustomerModel).copyWith(
          nextDueDate: newNextDueDate,
        );
        await updateCustomer(updatedCustomer);
      } catch (e) {
        print('Error updating customer nextDueDate: $e');
      }
    }

    // Persist created/updated payment in memory for this session
    final idx = _createdPayments.indexWhere((p) => p.id == updatedPayment.id);
    if (idx != -1) {
      _createdPayments[idx] = updatedPayment;
    } else {
      _createdPayments.add(updatedPayment);
    }
    await _onLoadPayments(const LoadPaymentsEvent(), emit);
  }

  Future<void> _onLoadPayments(
    LoadPaymentsEvent event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(const PaymentsLoading());

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // Combine mock payments with session-created ones, prioritizing session updates
      final mockList = _generateMockPayments();
      final Map<String, PaymentModel> paymentMap = {
        for (var p in mockList) p.id: p,
      };
      for (var p in _createdPayments) {
        paymentMap[p.id] = p;
      }
      var payments = paymentMap.values.toList();

      // Apply search filter
      final query = event.searchQuery?.trim().toLowerCase();
      if (query != null && query.isNotEmpty) {
        payments = payments
            .where((p) => p.customerName.toLowerCase().contains(query))
            .toList();
      }

      // Apply multi-status filter (case-insensitive check)
      if (event.filterStatuses != null && event.filterStatuses!.isNotEmpty) {
        payments = payments
            .where((p) => event.filterStatuses!
                .any((status) => status.toLowerCase() == p.status.toLowerCase()))
            .toList();
      }

      // Keep single-status filter too
      if (event.filterStatus != null) {
        payments = payments
            .where((p) => p.status.toLowerCase() == event.filterStatus!.toLowerCase())
            .toList();
      }

      // Compute totals on the full filtered list
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
    final statuses = [
      'paid',
      'unpaid',
      'partial',
      'failed',
    ];

    return List.generate(80, (i) {
      return PaymentModel(
        id: 'pay_$i',
        customerId: 'cust_${i % 30}',
        customerName: 'Customer ${i % 30 + 1}',
        amount: 1500,
        paidAmount: i % 4 == 0 ? 1500 : (i % 4 == 1 ? 0 : (i % 4 == 2 ? 750 : 0)),
        status: statuses[i % statuses.length],
        dueDate: baseDate.subtract(Duration(days: 30 - (i % 30))),
        completedDate: i % 4 == 0
            ? baseDate.subtract(Duration(days: 20 - (i % 20)))
            : null,
        method: i % 2 == 0 ? 'Bank Transfer' : 'Cash',
        notes: 'Monthly subscription payment',
        createdAt: baseDate.subtract(Duration(days: 40 - (i % 40))),
      );
    });
  }
}
