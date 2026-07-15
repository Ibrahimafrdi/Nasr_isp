import 'package:nasr_isp/core/constants/app_constants.dart';

class InventoryItemEntity {
  final String id;
  final String name;
  final InventoryCategory category;
  final String unit;
  final int quantityInStock;
  final int reorderLevel;
  final double unitCost;
  // What this item is sold/billed to the customer for — distinct from
  // unitCost (what the company paid). Snapshotted per-row into an
  // installation's BOM so material profit can be tracked per item.
  final double sellPrice;
  final String? supplier;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final InventoryConnectionType connectionType;

  const InventoryItemEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.quantityInStock,
    required this.reorderLevel,
    required this.unitCost,
    required this.sellPrice,
    this.supplier,
    this.notes,
    this.createdAt,
    this.updatedAt,
    required this.connectionType,
  });
}
