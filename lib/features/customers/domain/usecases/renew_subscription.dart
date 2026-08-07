import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/customers/domain/repositories/customer_repository.dart';
import 'package:nasr_isp/features/packages/domain/usecases/get_packages.dart';
import 'package:nasr_isp/features/packages/domain/usecases/resolve_package_cost.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';

/// What a renewal produced: the customer with their new expiry, and the
/// subscription charge that granted it.
class RenewalOutcome {
  /// The customer as persisted, carrying the new [CustomerEntity.nextDueDate].
  final CustomerEntity customer;

  /// The charge for the renewed month, after any merge with an existing row.
  final PaymentEntity payment;

  const RenewalOutcome({required this.customer, required this.payment});

  bool get isPaidInFull => payment.isSettled;

  /// Balance still owed on the renewed month. Non-zero means the operator
  /// took a part payment and must settle the rest from the Payments page.
  double get outstanding => payment.remainingAmount;

  /// The expiry the customer was renewed through.
  DateTime? get renewedUntil => payment.periodEnd;
}

/// Renews a customer's subscription for one month.
///
/// This is the only place that advances [CustomerEntity.nextDueDate] *against
/// a payment*. It used to happen as a side effect in three separate branches
/// of PaymentsBloc, keyed off whichever payment happened to land — which meant
/// settling an old partial balance could shunt a customer's expiry forward a
/// month for free. Money and time are now decided together, once:
///
///   * the expiry moves to one month after the renewal date,
///   * a `(customerId, billingMonth)` charge records what was billed and
///     collected for that period,
///   * the upstream package cost is snapshotted onto the charge so the
///     realized margin can be computed later without re-resolving packages.
///
/// The expiry advances even on a part payment: the operator has granted the
/// month, and the shortfall stays visible as an outstanding balance on the
/// charge rather than as a silently un-renewed customer.
///
/// The one other writer of `nextDueDate` is [SetCustomerStatus], reactivating
/// a customer onto a fresh cycle. That path bills nothing because no service
/// was delivered while the account was off — see its doc comment.
class RenewSubscription {
  final PaymentRepository paymentRepository;
  final CustomerRepository customerRepository;
  final GetPackages getPackages;

  RenewSubscription({
    required this.paymentRepository,
    required this.customerRepository,
    required this.getPackages,
  });

  Future<RenewalOutcome> call({
    required CustomerEntity customer,
    required double amountReceived,
    required DateTime renewalDate,
    required String method,
    String? notes,
  }) async {
    if (amountReceived < 0) {
      throw ArgumentError.value(
        amountReceived,
        'amountReceived',
        'A renewal cannot collect a negative amount',
      );
    }
    if (customer.monthlyBill <= 0) {
      throw StateError(
        'Customer ${customer.id} has no monthly bill set — assign a package or '
        'a negotiated rate before renewing.',
      );
    }
    if (amountReceived > customer.monthlyBill) {
      throw ArgumentError.value(
        amountReceived,
        'amountReceived',
        'Cannot collect more than the monthly bill of ${customer.monthlyBill}',
      );
    }

    final billingMonth = BillingCycle.monthKey(renewalDate);
    final periodEnd = BillingCycle.addMonths(renewalDate);
    final packageCost = await _resolvePackageCost(customer.packageId);

    final existing = await paymentRepository.getPaymentByCustomerAndMonth(
      customer.id,
      billingMonth,
    );

    final PaymentEntity charge;
    if (existing != null) {
      // A charge for this month already exists — a first-month bill from
      // account creation, or a second renewal inside the same calendar month.
      // Top it up in place; creating a second row would break the
      // (customerId, billingMonth) key that every monthly aggregate relies on.
      final paid = existing.paidAmount + amountReceived;
      final isPaidInFull = paid >= existing.amount;
      charge = existing.copyWith(
        paidAmount: paid,
        status: PaymentEntity.statusFor(
          amount: existing.amount,
          paidAmount: paid,
        ),
        completedDate: isPaidInFull ? renewalDate : null,
        method: method,
        notes: notes,
        paymentDate: renewalDate,
        periodEnd: periodEnd,
        packageCostAtBilling: existing.packageCostAtBilling ?? packageCost,
      );
      await paymentRepository.updatePayment(charge);
    } else {
      final isPaidInFull = amountReceived >= customer.monthlyBill;
      charge = PaymentEntity(
        // Discarded by the datasource, which assigns a collision-safe
        // Firestore auto-ID on insert.
        id: '',
        customerId: customer.id,
        customerName: customer.name,
        amount: customer.monthlyBill,
        paidAmount: amountReceived,
        status: PaymentEntity.statusFor(
          amount: customer.monthlyBill,
          paidAmount: amountReceived,
        ),
        // The date this charge fell due — the expiry it cures — not the next
        // one. The next expiry is [periodEnd].
        dueDate: customer.effectiveDueDate ?? renewalDate,
        completedDate: isPaidInFull ? renewalDate : null,
        method: method,
        notes: notes,
        billingMonth: billingMonth,
        createdAt: DateTime.now(),
        paymentDate: renewalDate,
        type: PaymentType.subscription,
        packageCostAtBilling: packageCost,
        periodEnd: periodEnd,
      );
      await paymentRepository.addPayment(charge);
    }

    final renewed = customer.copyWith(nextDueDate: periodEnd);
    await customerRepository.updateCustomer(renewed);

    return RenewalOutcome(customer: renewed, payment: charge);
  }

  /// The upstream cost for the renewed month. See [resolvePackageCost] for why
  /// an unresolvable cost is null rather than zero.
  Future<double?> _resolvePackageCost(String? packageId) =>
      resolvePackageCost(getPackages, packageId);
}
