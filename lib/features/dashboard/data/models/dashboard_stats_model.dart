import 'package:equatable/equatable.dart';

class DashboardStatsModel extends Equatable {
  final int totalCustomers;
  final int activeCustomers;
  final int expiredCustomers;
  final int expiringsoon;

  /// ACCRUAL run rate: the sum over all ACTIVE customers of
  /// (monthlyBill - package.costPrice). A full-month figure that does not
  /// depend on who has actually paid. First term of [netProfit].
  final double subscriberRunRateMargin;

  /// CASH BASIS: subscription payments with status 'paid' whose
  /// completedDate/createdAt falls in the current month.
  ///
  /// Deliberately NOT a term of [netProfit] — installation billing never
  /// enters the payments ledger, so this is not a complete cash picture.
  final double cashCollectedThisMonth;

  final double monthlyExpenses;

  /// ACCRUAL: netProfit = subscriberRunRateMargin
  ///                    + monthlyInstallationProfit
  ///                    - monthlyExpenses
  ///
  /// Does NOT reconcile against [cashCollectedThisMonth] — different basis.
  final double netProfit;

  final double pendingPayments;
  // Untruncated count backing the "Payments Overdue" alert — the
  // corresponding pendingPayments list on DashboardLoaded is capped to a
  // handful of rows for display, so this is the only accurate count.
  final int pendingPaymentsCount;
  final int pendingInstallations;

  /// All-time count of completed jobs, unlike the monthly money figures below.
  final int completedInstallations;

  /// ACCRUAL, completed jobs bucketed into the current month by
  /// (completedAt ?? createdAt). Total BILLED to the customer:
  /// installationCost + materialRevenue. Materials are billed on top of the
  /// setup fee, so they belong in revenue.
  ///
  /// Invariant: monthlyInstallationRevenue - monthlyInstallationCost
  ///            == monthlyInstallationProfit.
  final double monthlyInstallationRevenue;

  /// Materials at cost plus labour, same scope as
  /// [monthlyInstallationRevenue].
  final double monthlyInstallationCost;

  /// Second term of [netProfit]. Same scope as the two figures above.
  final double monthlyInstallationProfit;

  /// How many active customers have no usable package cost — either no
  /// package assigned, or a packageId that no longer resolves.
  ///
  /// Their upstream cost falls back to zero, so their entire monthly bill
  /// counts as margin and [subscriberRunRateMargin] is an UPPER BOUND
  /// whenever this is non-zero.
  final int unpricedCustomerCount;

  const DashboardStatsModel({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.expiredCustomers,
    required this.expiringsoon,
    required this.subscriberRunRateMargin,
    required this.cashCollectedThisMonth,
    required this.monthlyExpenses,
    required this.netProfit,
    required this.pendingPayments,
    required this.pendingPaymentsCount,
    required this.pendingInstallations,
    required this.completedInstallations,
    required this.monthlyInstallationRevenue,
    required this.monthlyInstallationCost,
    required this.monthlyInstallationProfit,
    this.unpricedCustomerCount = 0,
  });

  @override
  List<Object?> get props => [
    totalCustomers,
    activeCustomers,
    expiredCustomers,
    expiringsoon,
    subscriberRunRateMargin,
    cashCollectedThisMonth,
    monthlyExpenses,
    netProfit,
    pendingPayments,
    pendingPaymentsCount,
    pendingInstallations,
    completedInstallations,
    monthlyInstallationRevenue,
    monthlyInstallationCost,
    monthlyInstallationProfit,
    unpricedCustomerCount,
  ];
}
