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
  // Raw manual material/equipment cost — used as a fallback when no
  // itemsUsed BOM is supplied (e.g. the quick New Customer onboarding flow).
  final double? equipmentCost;
  // Technician/labor cost for the job. Defaults to null (treated as 0) so
  // installations created before this field existed are unaffected.
  final double? laborCost;

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
    this.equipmentCost,
    this.laborCost,
  });

  // Computed field: materialCost — prefers the itemsUsed BOM sum when
  // present (existing behavior, unchanged), otherwise falls back to the
  // raw equipmentCost override.
  double? get materialCost {
    if (itemsUsed != null && itemsUsed!.isNotEmpty) {
      return itemsUsed!.fold<double>(0.0, (sum, item) => sum + (item.quantity * item.costPriceAtTime));
    }
    return equipmentCost;
  }

  // Computed field: profit = installation fee - material/equipment cost - labor cost.
  // Returns null when there's no cost data at all, exactly like before.
  double? get profit {
    final cost = materialCost;
    final labor = laborCost ?? 0.0;
    if (cost == null && labor == 0.0) return null;
    return installationCost - (cost ?? 0.0) - labor;
  }
}
