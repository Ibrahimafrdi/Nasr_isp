import 'package:equatable/equatable.dart';

class SupplierEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final String? notes;
  final bool isActive;
  final double totalPurchased;
  final double totalPaid;
  final double pendingBalance;
  final DateTime? createdAt;

  const SupplierEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.notes,
    this.isActive = true,
    this.totalPurchased = 0.0,
    this.totalPaid = 0.0,
    this.pendingBalance = 0.0,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        address,
        notes,
        isActive,
        totalPurchased,
        totalPaid,
        pendingBalance,
        createdAt,
      ];
}

