import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_item_used_entity.dart';

class InstallationEntity {
  final String id;
  final String customerId;
  final String customerName;
  final ConnectionType connectionType;
  final DateTime installationDate;
  final String? assignedEmployeeId;
  final String? assignedEmployeeName;
  final double installationCost;
  final InstallationStatus status;
  final String? remarks;
  final List<InstallationItemUsedEntity>? itemsUsed;
  final DateTime createdAt;
  final DateTime? completedAt;

  const InstallationEntity({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.connectionType,
    required this.installationDate,
    this.assignedEmployeeId,
    this.assignedEmployeeName,
    required this.installationCost,
    required this.status,
    this.remarks,
    this.itemsUsed,
    required this.createdAt,
    this.completedAt,
  });

  // Computed field: materialCost
  double? get materialCost {
    if (itemsUsed == null || itemsUsed!.isEmpty) return null;
    return itemsUsed!.fold<double>(0.0, (sum, item) => sum + (item.quantity * item.costPriceAtTime));
  }

  // Computed field: profit
  double? get profit {
    final cost = materialCost;
    if (cost == null) return null;
    return installationCost - cost;
  }
}
