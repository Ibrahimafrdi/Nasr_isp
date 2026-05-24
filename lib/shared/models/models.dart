import 'package:equatable/equatable.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? profileImage;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, email, phone, role];
}

class CustomerModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String? email;
  final String packageName;
  final double monthlyRate;
  final DateTime expiryDate;
  final CustomerStatus status;
  final String? assignedEmployeeId;
  final DateTime createdAt;
  final double? balance;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.email,
    required this.packageName,
    required this.monthlyRate,
    required this.expiryDate,
    required this.status,
    this.assignedEmployeeId,
    required this.createdAt,
    this.balance,
  });

  int get daysUntilExpiry {
    return expiryDate.difference(DateTime.now()).inDays;
  }

  @override
  List<Object?> get props => [id, name, phone];
}

class PaymentModel extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final double paidAmount;
  final PaymentStatus status;
  final DateTime dueDate;
  final DateTime? completedDate;
  final String? method;
  final String? notes;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.paidAmount,
    required this.status,
    required this.dueDate,
    this.completedDate,
    this.method,
    this.notes,
    required this.createdAt,
  });

  double get remainingAmount => amount - paidAmount;
  bool get isOverdue =>
      DateTime.now().isAfter(dueDate) && status != PaymentStatus.completed;

  @override
  List<Object?> get props => [id, customerId];
}

class ExpenseModel extends Equatable {
  final String id;
  final String description;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String? notes;
  final String? attachmentUrl;
  final DateTime createdAt;

  const ExpenseModel({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
    this.attachmentUrl,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, category];
}

class EmployeeModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final double salary;
  final DateTime hireDate;
  final UserRole role;
  final bool isActive;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.salary,
    required this.hireDate,
    required this.role,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, phone];
}

class InstallationModel extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final double deviceCost;
  final double cableCost;
  final double routerCost;
  final double laborCost;
  final double otherCost;
  final double sellPrice;
  final DateTime installationDate;

  const InstallationModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.deviceCost,
    required this.cableCost,
    required this.routerCost,
    required this.laborCost,
    required this.otherCost,
    required this.sellPrice,
    required this.installationDate,
  });

  double get totalCost =>
      deviceCost + cableCost + routerCost + laborCost + otherCost;

  double get profit => sellPrice - totalCost;

  @override
  List<Object?> get props => [id, customerId];
}

class PackageModel extends Equatable {
  final String id;
  final String name;
  final double monthlyRate;
  final String speed;
  final String description;
  final bool isActive;

  const PackageModel({
    required this.id,
    required this.name,
    required this.monthlyRate,
    required this.speed,
    required this.description,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name];
}

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
