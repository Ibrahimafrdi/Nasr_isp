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

  const DashboardStatsModel({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.expiredCustomers,
    required this.expiringsoon,
    required this.monthlyRevenue,
    required this.monthlyExpenses,
    required this.netProfit,
    required this.pendingPayments,
  });

  @override
  List<Object?> get props => [
    totalCustomers,
    activeCustomers,
    monthlyRevenue,
    netProfit,
  ];
}