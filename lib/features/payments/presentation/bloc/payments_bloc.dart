import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/features/payments/domain/usecases/add_payment.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_payments.dart';
import 'package:nasr_isp/features/payments/domain/usecases/update_payment.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_payment_by_customer_and_month.dart';

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
  final DocumentSnapshot? lastDocument;

  const LoadPaymentsEvent({
    this.page = 1,
    this.searchQuery,
    this.filterStatus,
    this.filterStatuses,
    this.dateRangeStart,
    this.dateRangeEnd,
    this.lastDocument,
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
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PaymentsLoaded({
    required this.payments,
    required this.currentPage,
    required this.totalPages,
    required this.totalAmount,
    required this.collectedAmount,
    this.lastDocument,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [
    payments,
    currentPage,
    totalPages,
    totalAmount,
    collectedAmount,
    hasMore,
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
  final GetPayments getPayments;
  final AddPayment addPayment;
  final UpdatePayment updatePayment;
  final GetPaymentByCustomerAndMonth getPaymentByCustomerAndMonth;

  PaymentsBloc({
    required this.getPayments,
    required this.addPayment,
    required this.updatePayment,
    required this.getPaymentByCustomerAndMonth,
  }) : super(const PaymentsInitial()) {
    on<LoadPaymentsEvent>(_onLoadPayments);
    on<CreatePaymentEvent>(_onCreatePayment);
    on<UpdatePaymentEvent>(_onUpdatePayment);
  }

  /// Records a charge against `(customerId, billingMonth)`, merging into an
  /// existing row for that month rather than duplicating it.
  ///
  /// This handler used to also advance the customer's `nextDueDate` in two
  /// separate branches. It no longer touches the customer at all: the
  /// subscription cycle is owned end-to-end by RenewSubscription, which is
  /// reached from the Renew action on the Customers page. Keeping a second
  /// writer here meant that settling an old partial balance — or recording a
  /// first-month bill during account creation — could silently shunt a
  /// customer's expiry forward, which is precisely what made renewals
  /// impossible to reconcile.
  Future<void> _onCreatePayment(
    CreatePaymentEvent event,
    Emitter<PaymentsState> emit,
  ) async {
    try {
      final billingMonth = event.payment.billingMonth;
      if (billingMonth != null) {
        final existingPayment = await getPaymentByCustomerAndMonth(
          event.payment.customerId,
          billingMonth,
        );

        if (existingPayment != null) {
          final updatedPaidAmount =
              existingPayment.paidAmount + event.payment.paidAmount;
          final isPaidInFull = updatedPaidAmount >= existingPayment.amount;

          final updatedPayment = PaymentModel.from(existingPayment).copyWith(
            paidAmount: updatedPaidAmount,
            status: isPaidInFull ? 'paid' : 'partial',
            completedDate: isPaidInFull
                ? (event.payment.paymentDate ?? DateTime.now())
                : null,
            method: event.payment.method,
            notes: event.payment.notes,
            paymentDate: event.payment.paymentDate ?? DateTime.now(),
            packageCostAtBilling: existingPayment.packageCostAtBilling ??
                event.payment.packageCostAtBilling,
          );

          await updatePayment(updatedPayment);

          await Future.delayed(const Duration(milliseconds: 300));
          await _onLoadPayments(const LoadPaymentsEvent(), emit);
          return;
        }
      }

      await addPayment(event.payment);

      await Future.delayed(const Duration(milliseconds: 300));
      await _onLoadPayments(const LoadPaymentsEvent(), emit);
    } catch (e) {
      emit(PaymentsError(message: 'Failed to create payment: $e'));
    }
  }

  /// Settles money against an existing charge. Deliberately has no effect on
  /// the customer's expiry — see [_onCreatePayment]. Collecting an arrears
  /// balance pays for a period the customer has already been granted; it does
  /// not buy them another month.
  Future<void> _onUpdatePayment(
    UpdatePaymentEvent event,
    Emitter<PaymentsState> emit,
  ) async {
    try {
      await updatePayment(event.payment);

      await Future.delayed(const Duration(milliseconds: 300));
      await _onLoadPayments(const LoadPaymentsEvent(), emit);
    } catch (e) {
      emit(PaymentsError(message: 'Failed to update payment: $e'));
    }
  }

  Future<void> _onLoadPayments(
    LoadPaymentsEvent event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(const PaymentsLoading());
    try {
      const pageSize = 10;

      final entities = await getPayments(
        limit: pageSize + 1,
        lastDocument: event.lastDocument,
        searchQuery: event.searchQuery,
        filterStatuses: event.filterStatuses ??
            (event.filterStatus != null ? [event.filterStatus!] : null),
        dateRangeStart: event.dateRangeStart,
        dateRangeEnd: event.dateRangeEnd,
      );

      final hasMore = entities.length > pageSize;
      final pageEntities =
          hasMore ? entities.sublist(0, pageSize) : entities;

      var payments = pageEntities.map(PaymentModel.from).toList();

      final query = event.searchQuery?.trim().toLowerCase();
      if (query != null && query.isNotEmpty) {
        payments = payments
            .where((p) =>
                p.customerName.toLowerCase().contains(query) ||
                p.customerId.toLowerCase().contains(query))
            .toList();
      }

      final totalAmount =
          payments.fold<double>(0, (sum, p) => sum + p.amount);
      final collectedAmount =
          payments.fold<double>(0, (sum, p) => sum + p.paidAmount);

      final currentPage = event.page;
      final totalPages = hasMore ? currentPage + 1 : currentPage;

      emit(PaymentsLoaded(
        payments: payments,
        currentPage: currentPage,
        totalPages: totalPages,
        totalAmount: totalAmount,
        collectedAmount: collectedAmount,
        hasMore: hasMore,
      ));
    } catch (e) {
      emit(PaymentsError(message: 'Failed to load payments: $e'));
    }
  }
}
