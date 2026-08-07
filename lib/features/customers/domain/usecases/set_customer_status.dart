import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/customers/domain/repositories/customer_repository.dart';
import 'package:nasr_isp/features/packages/domain/usecases/get_packages.dart';
import 'package:nasr_isp/features/packages/domain/usecases/resolve_package_cost.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/domain/repositories/payment_repository.dart';

/// What should happen to the billing cycle when a customer comes back on
/// service after a spell as inactive.
enum ReactivationCycle {
  /// Keep the stored [CustomerEntity.nextDueDate]. The customer reappears with
  /// whatever expiry they had when they were deactivated — typically already
  /// lapsed, so they land in the Expired bucket with a lit Renew button and
  /// the operator settles it by collecting. No new charge is raised: whatever
  /// they owed for the interrupted period is already on the ledger.
  resumeExisting,

  /// Restart the cycle: the expiry moves to one month from the reactivation
  /// date, and that month is billed as an unpaid charge.
  startFresh,
}

/// Why a [ReactivationCycle.startFresh] reactivation raised no charge.
enum UnbilledReason {
  /// The customer has no monthly bill set, so there is no amount to bill.
  /// Assign a package or a negotiated rate, then collect via Renew.
  noMonthlyBill,

  /// A charge for that billing month already exists. Billing it again would
  /// break the `(customerId, billingMonth)` key every monthly aggregate
  /// relies on, and would double-bill the customer.
  monthAlreadyBilled,
}

/// What a status change produced.
class CustomerStatusOutcome {
  /// The customer as persisted.
  final CustomerEntity customer;

  /// The charge raised for the resumed month, if one was. Only ever non-null
  /// for a [ReactivationCycle.startFresh] reactivation.
  final PaymentEntity? charge;

  /// Set when a fresh cycle was requested but no charge could be raised.
  final UnbilledReason? unbilledReason;

  const CustomerStatusOutcome({
    required this.customer,
    this.charge,
    this.unbilledReason,
  });

  bool get billed => charge != null;
}

/// Moves a customer on or off service.
///
/// Deactivating is deliberately not a delete. The record, its payment history
/// and its stored expiry all survive, so a customer who suspends over winter
/// can be brought back without re-entering anything. What changes is that
/// every billing surface stops counting them: [CustomerEntity.isExpiredAt] and
/// [CustomerEntity.isDueForRenewalAt] both return false off service, which is
/// what pulls them out of the dashboard's expired/expiring tiles and hides the
/// Renew action.
///
/// Reactivation is the interesting direction, because the account has a stale
/// expiry on it. [ReactivationCycle] makes the operator say which reading is
/// true rather than picking one silently — the difference is a month of
/// revenue.
class SetCustomerStatus {
  final CustomerRepository customerRepository;
  final PaymentRepository paymentRepository;
  final GetPackages getPackages;

  SetCustomerStatus({
    required this.customerRepository,
    required this.paymentRepository,
    required this.getPackages,
  });

  /// [asOf] is the reactivation date a [ReactivationCycle.startFresh] cycle is
  /// measured and billed from; it is ignored when deactivating or resuming.
  Future<CustomerStatusOutcome> call({
    required CustomerEntity customer,
    required bool active,
    ReactivationCycle cycle = ReactivationCycle.resumeExisting,
    DateTime? asOf,
  }) async {
    if (!active) {
      // nextDueDate is left exactly as it stands. It is what
      // ReactivationCycle.resumeExisting resumes, and clearing it would also
      // destroy the record of how far the customer was paid up.
      final updated = customer.copyWith(status: CustomerEntity.statusInactive);
      await customerRepository.updateCustomer(updated);
      return CustomerStatusOutcome(customer: updated);
    }

    if (cycle == ReactivationCycle.resumeExisting) {
      final updated = customer.copyWith(status: CustomerEntity.statusActive);
      await customerRepository.updateCustomer(updated);
      return CustomerStatusOutcome(customer: updated);
    }

    return _startFresh(customer, BillingCycle.dateOnly(asOf ?? DateTime.now()));
  }

  /// Puts the customer back on a new cycle and bills them for it.
  ///
  /// This is the second writer of [CustomerEntity.nextDueDate] besides
  /// RenewSubscription, and unlike that one it moves the expiry without taking
  /// any money — so it raises the charge for the month it just granted, unpaid.
  /// The customer returns owing their monthly bill, which is what keeps them
  /// out of the "on service but never billed" hole: without the charge they
  /// would count toward the accrual run rate and the active-subscriber tiles
  /// while contributing no billed line, quietly overstating margin.
  ///
  /// The charge is shaped exactly like the one account creation writes — same
  /// `(customerId, billingMonth)` key, same cost snapshot, same covered period
  /// — so the resumed month reconciles alongside every other month. The only
  /// difference is that nothing has been collected against it yet.
  Future<CustomerStatusOutcome> _startFresh(
    CustomerEntity customer,
    DateTime reactivationDate,
  ) async {
    final periodEnd = BillingCycle.addMonths(reactivationDate);
    final reactivated = customer.copyWith(
      status: CustomerEntity.statusActive,
      nextDueDate: periodEnd,
    );

    // A bill of zero is not a bill. Reactivation must still go through —
    // refusing to restore service over a missing rate would be a worse
    // failure than an unbilled month the operator can see and fix.
    if (customer.monthlyBill <= 0) {
      await customerRepository.updateCustomer(reactivated);
      return CustomerStatusOutcome(
        customer: reactivated,
        unbilledReason: UnbilledReason.noMonthlyBill,
      );
    }

    final billingMonth = BillingCycle.monthKey(reactivationDate);
    final existing = await paymentRepository.getPaymentByCustomerAndMonth(
      customer.id,
      billingMonth,
    );

    // Already billed for this month — deactivated and reactivated inside the
    // same calendar month, most likely. Leave that row alone: it is the
    // customer's bill for the period, and a second one would both double-bill
    // them and break the (customerId, billingMonth) uniqueness key.
    if (existing != null) {
      await customerRepository.updateCustomer(reactivated);
      return CustomerStatusOutcome(
        customer: reactivated,
        unbilledReason: UnbilledReason.monthAlreadyBilled,
      );
    }

    final charge = PaymentEntity(
      // Discarded by the datasource, which assigns a collision-safe
      // Firestore auto-ID on insert.
      id: '',
      customerId: customer.id,
      customerName: customer.name,
      amount: customer.monthlyBill,
      // Billed in advance and not yet collected, so this resolves to
      // 'unpaid' — partial would mean some cash arrived, and none has.
      paidAmount: 0,
      status: PaymentEntity.statusFor(
        amount: customer.monthlyBill,
        paidAmount: 0,
      ),
      // The day service resumed — the day this bill fell due — not the expiry
      // it buys. That is [periodEnd].
      dueDate: reactivationDate,
      completedDate: null,
      method: null,
      notes: 'Reactivation — first month of resumed service, not yet collected',
      billingMonth: billingMonth,
      createdAt: DateTime.now(),
      // No money has moved, so there is no payment date to record.
      paymentDate: null,
      type: PaymentType.subscription,
      packageCostAtBilling: await resolvePackageCost(
        getPackages,
        customer.packageId,
      ),
      periodEnd: periodEnd,
    );
    await paymentRepository.addPayment(charge);
    await customerRepository.updateCustomer(reactivated);

    return CustomerStatusOutcome(customer: reactivated, charge: charge);
  }
}
