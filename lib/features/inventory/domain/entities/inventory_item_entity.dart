import 'package:nasr_isp/core/constants/app_constants.dart';

class InventoryItemEntity {
  final String id;
  final String name;
  final InventoryCategory category;
  final String unit;
  final int quantityInStock;
  final int reorderLevel;
  final double unitCost;
  final String? supplier;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Null means unspecified/legacy — only matched by the "All" filter, not
  // by the Wireless or Fiber filter chips.
  final InventoryConnectionType? connectionType;

  const InventoryItemEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.quantityInStock,
    required this.reorderLevel,
    required this.unitCost,
    this.supplier,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.connectionType,
  });
}
