import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/index.dart';
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
  // LEGACY, read-only. A flat material/equipment cost carried by installation
  // documents created before the itemsUsed BOM existed. No UI writes this
  // field any more — both the New Customer onboarding flow and the
  // Installations dialog write a real BOM. It survives solely so materialCost
  // and profit still resolve for historical records. Do not add a form field
  // for it; add BOM rows instead.
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

  /// Materials consumed by this job: the itemised BOM when present, otherwise
  /// the legacy lump-sum [equipmentCost]. The selection rule is unchanged —
  /// only the arithmetic moved into [MaterialTotals].
  MaterialTotals get materials {
    final items = itemsUsed;
    if (items != null && items.isNotEmpty) {
      return MaterialTotals.of<InstallationItemUsedEntity>(
        items,
        quantity: (i) => i.quantity,
        unitCost: (i) => i.costPriceAtTime,
        sellPrice: (i) => i.sellPriceAtTime,
      );
    }
    return MaterialTotals.lumpSum(equipmentCost);
  }

  /// This job's financial position.
  ///
  /// Materials are billed to the customer ON TOP of the setup fee, so:
  ///   billed = installationCost + materials.revenue
  ///   cost   = materials.cost + laborCost
  MoneyLine get money => MoneyLine(
        amountBilled: installationCost + materials.revenue,
        costIncurred: materials.cost + (laborCost ?? 0.0),
      );

  /// Material cost, or null when no material information was ever recorded.
  /// Retained purely so the UI can render 'N/A' in the Material Cost column —
  /// never use it for arithmetic, use [money] or [materials].
  double? get materialCost => materials.isRecorded ? materials.cost : null;

  /// What the BOM items are billed for. Zero when there is no itemised BOM,
  /// since the legacy equipmentCost fallback carries no per-item sell price.
  double get materialRevenue => materials.revenue;

  /// True when this job has any recorded cost input, material or labour.
  ///
  /// When false, [profit] is still exact — it simply equals the amount billed,
  /// because no costs were logged against the job. Use this to caveat the
  /// figure in the UI, not to hide it.
  bool get hasCostData => materials.isRecorded || (laborCost ?? 0.0) != 0.0;

  /// Profit for this job: billed minus cost.
  ///
  /// Non-nullable. Under "materials billed on top" every installation has a
  /// knowable profit, so a fee-only job reports its fee rather than 'N/A' —
  /// suppressing it hid real money and made the column un-summable, which is
  /// how the aggregate cards were able to drift away from the rows.
  double get profit => money.profit;

  /// Rebuilds this installation with selected fields replaced.
  ///
  /// Prefer this over constructing a fresh InstallationEntity in edit flows: a
  /// new constructor call silently defaults every unpassed optional field to
  /// null, which is how laborCost and equipmentCost used to be wiped on save.
  ///
  /// Note that copyWith cannot set a nullable field back to null. Clearing the
  /// BOM is done by passing `const []` — [materials] treats an empty list and
  /// null identically. Clearing completedAt is owned by
  /// InstallationRemoteDataSourceImpl.updateInstallation.
  InstallationEntity copyWith({
    String? id,
    String? customerId,
    String? customerName,
    ConnectionType? connectionType,
    DateTime? installationDate,
    String? assignedEmployeeId,
    String? assignedEmployeeName,
    double? installationCost,
    InstallationStatus? status,
    String? remarks,
    List<InstallationItemUsedEntity>? itemsUsed,
    DateTime? createdAt,
    DateTime? completedAt,
    double? equipmentCost,
    double? laborCost,
  }) {
    return InstallationEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      connectionType: connectionType ?? this.connectionType,
      installationDate: installationDate ?? this.installationDate,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      assignedEmployeeName: assignedEmployeeName ?? this.assignedEmployeeName,
      installationCost: installationCost ?? this.installationCost,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      itemsUsed: itemsUsed ?? this.itemsUsed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      equipmentCost: equipmentCost ?? this.equipmentCost,
      laborCost: laborCost ?? this.laborCost,
    );
  }
}
