import 'package:equatable/equatable.dart';
import 'package:nasr_isp/core/finance/index.dart';

/// What a payment row is billing for.
///
/// Subscription and installation money have different lifecycles and different
/// cost bases, and folding them into one untyped ledger is what made
/// "collected this month" impossible to reconcile against anything. Every
/// aggregate that talks about the recurring business must filter on
/// [PaymentType.subscription].
enum PaymentType {
  subscription,
  installation;

  /// Legacy documents carry no `type` field at all. Every payment written
  /// before the discriminator existed was subscription billing — installation
  /// money has never reached this collection — so that is the safe default.
  static PaymentType fromName(String? raw) {
    switch (raw) {
      case 'installation':
        return PaymentType.installation;
      default:
        return PaymentType.subscription;
    }
  }
}

class PaymentEntity extends Equatable {
  final String id;
  final String customerId;
  final String customerName;

  /// The full amount billed for [billingMonth] — not the amount handed over.
  final double amount;

  /// Cash actually received against [amount] so far, across any number of
  /// instalments.
  final double paidAmount;

  /// One of `'paid' | 'unpaid' | 'partial'`. Normalized on read by
  /// PaymentRemoteDataSourceImpl, which folds the legacy
  /// `completed`/`pending`/`failed` vocabulary onto these three.
  final String status;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final String? method;
  final String? notes;

  /// `YYYY-MM` bucket this charge covers. Together with [customerId] this is
  /// the uniqueness key for a subscription charge: one row per customer per
  /// month, topped up in place rather than duplicated.
  final String? billingMonth;
  final DateTime? createdAt;
  final DateTime? paymentDate;

  final PaymentType type;

  /// The ISP's upstream cost for the period this row covers, snapshotted at
  /// renewal time.
  ///
  /// Stored rather than joined so that a later package re-price cannot rewrite
  /// history, and so a margin figure can be computed without resolving
  /// packages. Null on records written before the snapshot existed — callers
  /// must decide on a fallback rather than treating null as zero, since a zero
  /// cost reports the entire bill as margin.
  final double? packageCostAtBilling;

  /// The expiry this payment renewed the customer through. Null for legacy
  /// rows and for non-subscription billing.
  final DateTime? periodEnd;

  const PaymentEntity({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.paidAmount,
    required this.status,
    this.dueDate,
    this.completedDate,
    this.method,
    this.notes,
    this.billingMonth,
    this.createdAt,
    this.paymentDate,
    this.type = PaymentType.subscription,
    this.packageCostAtBilling,
    this.periodEnd,
  });

  double get remainingAmount => (amount - paidAmount).clamp(0, double.infinity);

  bool get isSettled => status == 'paid';

  bool get isSubscription => type == PaymentType.subscription;

  /// Margin realized on the cash actually in hand.
  ///
  /// The upstream cost is incurred for the whole period whether or not the
  /// customer paid in full, so it is charged at full weight against a partial
  /// collection — an under-collected month can and should read as a loss.
  ///
  /// Pass [fallbackCost] (the customer's currently-resolved package cost) for
  /// rows that predate [packageCostAtBilling]; leaving it at zero silently
  /// reports those rows as 100% margin.
  MoneyLine collectedMargin({double fallbackCost = 0.0}) => MoneyLine(
        amountBilled: paidAmount,
        costIncurred: packageCostAtBilling ?? fallbackCost,
      );

  /// Margin this row will be worth once collected in full. Summed over every
  /// active subscriber's current month, this is the accrual run rate.
  MoneyLine billedMargin({double fallbackCost = 0.0}) => MoneyLine(
        amountBilled: amount,
        costIncurred: packageCostAtBilling ?? fallbackCost,
      );

  @override
  List<Object?> get props => [
    id,
    customerId,
    customerName,
    amount,
    paidAmount,
    status,
    dueDate,
    completedDate,
    method,
    notes,
    billingMonth,
    createdAt,
    paymentDate,
    type,
    packageCostAtBilling,
    periodEnd,
  ];

  PaymentEntity copyWith({
    String? id,
    String? customerId,
    String? customerName,
    double? amount,
    double? paidAmount,
    String? status,
    DateTime? dueDate,
    DateTime? completedDate,
    String? method,
    String? notes,
    String? billingMonth,
    DateTime? createdAt,
    DateTime? paymentDate,
    PaymentType? type,
    double? packageCostAtBilling,
    DateTime? periodEnd,
  }) => PaymentEntity(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    amount: amount ?? this.amount,
    paidAmount: paidAmount ?? this.paidAmount,
    status: status ?? this.status,
    dueDate: dueDate ?? this.dueDate,
    completedDate: completedDate ?? this.completedDate,
    method: method ?? this.method,
    notes: notes ?? this.notes,
    billingMonth: billingMonth ?? this.billingMonth,
    createdAt: createdAt ?? this.createdAt,
    paymentDate: paymentDate ?? this.paymentDate,
    type: type ?? this.type,
    packageCostAtBilling: packageCostAtBilling ?? this.packageCostAtBilling,
    periodEnd: periodEnd ?? this.periodEnd,
  );
}
