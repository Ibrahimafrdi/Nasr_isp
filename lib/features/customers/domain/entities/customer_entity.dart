import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';

class CustomerEntity {
  final String id;
  final String name;
  final String phone;
  final String cnic;
  final String address;
  final String connectionType;
  final String? packageId;
  final double monthlyBill;
  final String status;
  final String notes;
  final DateTime? createdAt;
  final DateTime? joinDate;
  final DateTime? nextDueDate;

  const CustomerEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.cnic,
    required this.address,
    required this.connectionType,
    this.packageId,
    required this.monthlyBill,
    required this.status,
    required this.notes,
    this.createdAt,
    this.joinDate,
    this.nextDueDate,
  });

  /// Calculates monthly profit for this customer:
  /// customer.monthlyBill - package.costPrice
  /// If [package] is null or not found, cost price defaults to 0.0 safely.
  double calculateProfit(PackageEntity? package) {
    final costPrice = package?.costPrice ?? 0.0;
    return monthlyBill - costPrice;
  }
}
