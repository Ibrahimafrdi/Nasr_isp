import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';

/// In-progress (unsaved) BOM row shape shared by every installation form —
/// keys: 'itemId' (String), 'qty' (int), 'unitCost' (double, cost snapshot
/// at selection time), 'sellPrice' (double, sell-price snapshot at
/// selection time).
typedef InstallationItemRow = Map<String, dynamic>;

/// Matches inventory items tagged for [connectionType] (or "both"), one
/// qty-1 row per match with its current unit cost snapshotted in. Used to
/// seed a BOM the moment a connection type is picked. Callers are
/// responsible for only invoking this when the existing BOM is empty and
/// unlocked — this function itself has no opinion on either.
List<InstallationItemRow> autoSelectInstallationItems(
  ConnectionType connectionType,
  List<InventoryItemEntity> inventoryItems,
) {
  final matches = inventoryItems.where((invItem) {
    if (invItem.connectionType == InventoryConnectionType.both) {
      return true;
    }
    return connectionType == ConnectionType.wireless
        ? invItem.connectionType == InventoryConnectionType.wireless
        : invItem.connectionType == InventoryConnectionType.opticalFibre;
  }).toList();

  return matches
      .map((invItem) => <String, dynamic>{
            'itemId': invItem.id,
            'qty': 1,
            'unitCost': invItem.unitCost,
            'sellPrice': invItem.sellPrice,
          })
      .toList();
}
