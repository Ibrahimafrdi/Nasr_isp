import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/installations/presentation/utils/installation_item_autofill.dart';
import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';

InventoryItemEntity _item(String id, InventoryConnectionType type) {
  return InventoryItemEntity(
    id: id,
    name: id,
    category: InventoryCategory.equipment,
    unit: 'pcs',
    quantityInStock: 10,
    reorderLevel: 1,
    unitCost: 100,
    sellPrice: 150,
    connectionType: type,
  );
}

void main() {
  group('autoSelectInstallationItems', () {
    test('adds every item tagged for the selected type, not just the first', () {
      final inventory = [
        _item('w1', InventoryConnectionType.wireless),
        _item('w2', InventoryConnectionType.wireless),
        _item('w3', InventoryConnectionType.wireless),
        _item('f1', InventoryConnectionType.opticalFibre),
      ];

      final rows = autoSelectInstallationItems(ConnectionType.wireless, inventory);

      expect(rows.length, 3);
      expect(rows.map((r) => r['itemId']).toSet(), {'w1', 'w2', 'w3'});
      expect(rows.every((r) => r['qty'] == 1), isTrue);
    });

    test('includes items tagged "both" alongside the type-specific ones', () {
      final inventory = [
        _item('w1', InventoryConnectionType.wireless),
        _item('b1', InventoryConnectionType.both),
        _item('f1', InventoryConnectionType.opticalFibre),
      ];

      final rows = autoSelectInstallationItems(ConnectionType.wireless, inventory);

      expect(rows.map((r) => r['itemId']).toSet(), {'w1', 'b1'});
    });

    test('snapshots each matched item\'s current unit cost', () {
      final inventory = [_item('w1', InventoryConnectionType.wireless)];
      final rows = autoSelectInstallationItems(ConnectionType.wireless, inventory);
      expect(rows.single['unitCost'], 100.0);
    });
  });
}
