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
  /// Buckets by WHEN THE MONEY ARRIVED, so a late payment for an older month
  /// counts here. Use [currentMonthCollected] for the figure that reconciles
  /// against the run rate.
  ///
  /// Deliberately NOT a term of [netProfit] — installation billing never
  /// enters the payments ledger, so this is not a complete cash picture.
  final double cashCollectedThisMonth;

  // ── Current billing month ───────────────────────────────────────────────
  // The four figures below are all scoped to subscription charges whose
  // billingMonth is the current YYYY-MM — i.e. WHAT THIS MONTH IS WORTH,
  // regardless of when the cash landed. That scoping is what lets them
  // reconcile against [subscriberRunRateMargin], which is also a
  // this-month-only accrual figure.

  /// Σ `amount` over this month's subscription charges — what the customers
  /// who have been renewed so far were billed.
  final double currentMonthBilled;

  /// Σ `paidAmount` over the same charges — what has actually been collected
  /// against this month.
  final double currentMonthCollected;

  /// Σ (`paidAmount` − upstream cost) over the same charges: the margin
  /// actually realized on this month's renewals.
  ///
  /// The upstream cost is charged at full weight even against a part
  /// collection, because the ISP pays for the bandwidth either way — an
  /// under-collected month can and should read as a loss.
  ///
  /// INVARIANT: when every active subscriber has been renewed and has paid in
  /// full, this equals [subscriberRunRateMargin]. The gap between the two is
  /// [marginNotYetCollected] — the month's uncollected profit.
  final double currentMonthMarginCollected;

  /// Σ `remainingAmount` over the same charges: billed this month, renewed,
  /// but only part paid.
  final double currentMonthOutstanding;

  /// Σ `monthlyBill` over ACTIVE customers who have lapsed and have no charge
  /// for the current month at all — renewals that have not even been started.
  ///
  /// Disjoint from [currentMonthOutstanding] by construction: a customer with
  /// a charge for this month is excluded from this figure, so the two can be
  /// added without double counting.
  final double expiredCustomersDue;

  /// How many customers make up [expiredCustomersDue].
  final int expiredCustomersDueCount;

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
    this.currentMonthBilled = 0,
    this.currentMonthCollected = 0,
    this.currentMonthMarginCollected = 0,
    this.currentMonthOutstanding = 0,
    this.expiredCustomersDue = 0,
    this.expiredCustomersDueCount = 0,
  });

  /// Margin this month has earned on paper but not yet in cash — the headroom
  /// between what the active book is worth and what has been collected for it.
  ///
  /// Zero once every active subscriber has renewed and paid in full. Clamped
  /// at zero so an over-collected month (arrears from a previous month landing
  /// against this one) does not render as negative headroom.
  double get marginNotYetCollected =>
      (subscriberRunRateMargin - currentMonthMarginCollected)
          .clamp(0.0, double.infinity);

  /// Share of this month's accrual margin already realized in cash, 0..1.
  /// Null when there is no active book to collect against.
  double? get marginCollectionRate => subscriberRunRateMargin <= 0
      ? null
      : (currentMonthMarginCollected / subscriberRunRateMargin)
          .clamp(0.0, 1.0);

  /// Everything still to collect for the current month: part-paid renewals
  /// plus lapsed customers who have not been renewed at all.
  double get pendingThisMonth => currentMonthOutstanding + expiredCustomersDue;

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
    currentMonthBilled,
    currentMonthCollected,
    currentMonthMarginCollected,
    currentMonthOutstanding,
    expiredCustomersDue,
    expiredCustomersDueCount,
  ];
}
