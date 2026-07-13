import 'package:equatable/equatable.dart';

class DashboardStatsModel extends Equatable {
  final int totalCustomers;
  final int activeCustomers;
  final int expiredCustomers;
  final int expiringsoon;
  final double monthlyRevenue;
  final double monthlyExpenses;
  final double netProfit;
  final double pendingPayments;
  // Untruncated count backing the "Payments Overdue" alert — the
  // corresponding pendingPayments list on DashboardLoaded is capped to a
  // handful of rows for display, so this is the only accurate count.
  final int pendingPaymentsCount;
  final int pendingInstallations;
  final int completedInstallations;
  // Installation-driven financials for completed jobs this month — separate
  // from monthlyRevenue/netProfit (payments collected minus expenses logged),
  // since installation profit and company cash flow are distinct concerns.
  final double monthlyInstallationRevenue;
  final double monthlyInstallationCost;
  final double monthlyInstallationProfit;

  const DashboardStatsModel({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.expiredCustomers,
    required this.expiringsoon,
    required this.monthlyRevenue,
    required this.monthlyExpenses,
    required this.netProfit,
    required this.pendingPayments,
    required this.pendingPaymentsCount,
    required this.pendingInstallations,
    required this.completedInstallations,
    required this.monthlyInstallationRevenue,
    required this.monthlyInstallationCost,
    required this.monthlyInstallationProfit,
  });

  @override
  List<Object?> get props => [
    totalCustomers,
    activeCustomers,
    expiredCustomers,
    expiringsoon,
    monthlyRevenue,
    monthlyExpenses,
    netProfit,
    pendingPayments,
    pendingPaymentsCount,
    pendingInstallations,
    completedInstallations,
    monthlyInstallationRevenue,
    monthlyInstallationCost,
    monthlyInstallationProfit,
  ];
}