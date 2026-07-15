import 'package:nasr_isp/core/constants/app_constants.dart';

/// One entry in the client-supplied device/material catalog. Powers both
/// Firestore seeding and the "pick from catalog" autocomplete shown when
/// staff add a new inventory item.
class InventoryCatalogEntry {
  final String name;
  final InventoryCategory category;
  final InventoryConnectionType connectionType;
  final String unit;
  final int quantityInStock;
  final int reorderLevel;
  final double unitCost;

  const InventoryCatalogEntry({
    required this.name,
    required this.category,
    required this.connectionType,
    required this.unit,
    required this.quantityInStock,
    required this.reorderLevel,
    required this.unitCost,
  });
}

/// Client-supplied device/material catalog, normalized (typos fixed, plain
/// numerals instead of superscript) and tagged by which job type
/// (wireless/fiber/both) each item is used for.
const List<InventoryCatalogEntry> kInventoryCatalog = [
  // Wireless stock
  InventoryCatalogEntry(name: 'Powerbeam AC Gen 2', category: InventoryCategory.equipment, connectionType: InventoryConnectionType.wireless, unit: 'pcs', quantityInStock: 10, reorderLevel: 3, unitCost: 18000),
  InventoryCatalogEntry(name: 'Powerbeam M5', category: InventoryCategory.equipment, connectionType: InventoryConnectionType.wireless, unit: 'pcs', quantityInStock: 10, reorderLevel: 3, unitCost: 15000),
  InventoryCatalogEntry(name: 'Litebeam AC Gen 2', category: InventoryCategory.equipment, connectionType: InventoryConnectionType.wireless, unit: 'pcs', quantityInStock: 10, reorderLevel: 3, unitCost: 12000),
  InventoryCatalogEntry(name: 'Litebeam M5', category: InventoryCategory.equipment, connectionType: InventoryConnectionType.wireless, unit: 'pcs', quantityInStock: 10, reorderLevel: 3, unitCost: 9000),
  InventoryCatalogEntry(name: 'Wireless Router', category: InventoryCategory.equipment, connectionType: InventoryConnectionType.wireless, unit: 'pcs', quantityInStock: 15, reorderLevel: 5, unitCost: 3500),
  InventoryCatalogEntry(name: 'Cat6 Cable', category: InventoryCategory.consumable, connectionType: InventoryConnectionType.wireless, unit: 'meters', quantityInStock: 500, reorderLevel: 100, unitCost: 35),
  InventoryCatalogEntry(name: 'POE Injector', category: InventoryCategory.equipment, connectionType: InventoryConnectionType.wireless, unit: 'pcs', quantityInStock: 20, reorderLevel: 5, unitCost: 800),
  InventoryCatalogEntry(name: 'POE Cable', category: InventoryCategory.consumable, connectionType: InventoryConnectionType.wireless, unit: 'meters', quantityInStock: 300, reorderLevel: 50, unitCost: 40),
  InventoryCatalogEntry(name: 'Power Adapter', category: InventoryCategory.equipment, connectionType: InventoryConnectionType.wireless, unit: 'pcs', quantityInStock: 20, reorderLevel: 5, unitCost: 600),
  InventoryCatalogEntry(name: 'Connector', category: InventoryCategory.consumable, connectionType: InventoryConnectionType.wireless, unit: 'pcs', quantityInStock: 100, reorderLevel: 20, unitCost: 30),
  InventoryCatalogEntry(name: 'Pole & Frame', category: InventoryCategory.equipment, connectionType: InventoryConnectionType.wireless, unit: 'pcs', quantityInStock: 15, reorderLevel: 5, unitCost: 2500),
  InventoryCatalogEntry(name: 'Steel Wire', category: InventoryCategory.consumable, connectionType: InventoryConnectionType.wireless, unit: 'meters', quantityInStock: 200, reorderLevel: 50, unitCost: 50),

  // Fiber stock
  InventoryCatalogEntry(name: 'Fiber Router', category: InventoryCategory.equipment, connectionType: InventoryConnectionType.opticalFibre, unit: 'pcs', quantityInStock: 15, reorderLevel: 5, unitCost: 4000),
  InventoryCatalogEntry(name: 'Fiber Cable', category: InventoryCategory.consumable, connectionType: InventoryConnectionType.opticalFibre, unit: 'meters', quantityInStock: 1000, reorderLevel: 200, unitCost: 20),
  InventoryCatalogEntry(name: 'Patch Cord', category: InventoryCategory.consumable, connectionType: InventoryConnectionType.opticalFibre, unit: 'pcs', quantityInStock: 100, reorderLevel: 20, unitCost: 250),
  InventoryCatalogEntry(name: '1x8 Splitter', category: InventoryCategory.equipment, connectionType: InventoryConnectionType.opticalFibre, unit: 'pcs', quantityInStock: 10, reorderLevel: 3, unitCost: 1200),
  InventoryCatalogEntry(name: '1x4 Splitter', category: InventoryCategory.equipment, connectionType: InventoryConnectionType.opticalFibre, unit: 'pcs', quantityInStock: 10, reorderLevel: 3, unitCost: 800),
  InventoryCatalogEntry(name: '1x2 Splitter', category: InventoryCategory.equipment, connectionType: InventoryConnectionType.opticalFibre, unit: 'pcs', quantityInStock: 10, reorderLevel: 3, unitCost: 500),
  InventoryCatalogEntry(name: 'Large DP Box', category: InventoryCategory.equipment, connectionType: InventoryConnectionType.opticalFibre, unit: 'pcs', quantityInStock: 8, reorderLevel: 2, unitCost: 3500),
  InventoryCatalogEntry(name: 'Small DP Box', category: InventoryCategory.equipment, connectionType: InventoryConnectionType.opticalFibre, unit: 'pcs', quantityInStock: 8, reorderLevel: 2, unitCost: 1800),
  InventoryCatalogEntry(name: 'Splicing Sleeve', category: InventoryCategory.consumable, connectionType: InventoryConnectionType.opticalFibre, unit: 'pcs', quantityInStock: 200, reorderLevel: 50, unitCost: 15),
  InventoryCatalogEntry(name: 'Yellow Tape', category: InventoryCategory.consumable, connectionType: InventoryConnectionType.opticalFibre, unit: 'pcs', quantityInStock: 50, reorderLevel: 10, unitCost: 60),
  InventoryCatalogEntry(name: 'White Tape', category: InventoryCategory.consumable, connectionType: InventoryConnectionType.opticalFibre, unit: 'pcs', quantityInStock: 50, reorderLevel: 10, unitCost: 60),
  InventoryCatalogEntry(name: 'Double Sided Tape', category: InventoryCategory.consumable, connectionType: InventoryConnectionType.opticalFibre, unit: 'pcs', quantityInStock: 50, reorderLevel: 10, unitCost: 80),

  // Shared between both job types
  InventoryCatalogEntry(name: 'Cable Tie', category: InventoryCategory.consumable, connectionType: InventoryConnectionType.both, unit: 'box', quantityInStock: 30, reorderLevel: 10, unitCost: 150),
];
