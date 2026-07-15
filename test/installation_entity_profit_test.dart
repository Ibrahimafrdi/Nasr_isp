import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_item_used_entity.dart';

InstallationEntity _installation({
  double installationCost = 0,
  List<InstallationItemUsedEntity>? itemsUsed,
  double? equipmentCost,
  double? laborCost,
}) {
  return InstallationEntity(
    id: 'i1',
    customerId: 'c1',
    customerName: 'Test Customer',
    connectionType: ConnectionType.wireless,
    installationDate: DateTime(2026, 1, 1),
    installationCost: installationCost,
    status: InstallationStatus.completed,
    itemsUsed: itemsUsed,
    createdAt: DateTime(2026, 1, 1),
    equipmentCost: equipmentCost,
    laborCost: laborCost,
  );
}

InstallationItemUsedEntity _item({
  required double cost,
  required double sell,
  int qty = 1,
}) {
  return InstallationItemUsedEntity(
    inventoryItemId: 'inv1',
    itemName: 'Router',
    quantity: qty,
    costPriceAtTime: cost,
    sellPriceAtTime: sell,
  );
}

void main() {
  group('InstallationEntity profit formula', () {
    test('with an itemized BOM, profit includes material markup (sell - cost)', () {
      final inst = _installation(
        installationCost: 1000,
        laborCost: 200,
        itemsUsed: [_item(cost: 100, sell: 150, qty: 2)],
      );

      expect(inst.materialCost, 200); // 2 * 100
      expect(inst.materialRevenue, 300); // 2 * 150
      // 1000 (fee) - 200 (cost) - 200 (labor) + 300 (material revenue) = 900
      expect(inst.profit, 900);
    });

    test('legacy itemsUsed with no sellPriceAtTime (defaults 0) behaves like before', () {
      final inst = _installation(
        installationCost: 1000,
        laborCost: 200,
        itemsUsed: [
          InstallationItemUsedEntity(
            inventoryItemId: 'inv1',
            itemName: 'Router',
            quantity: 2,
            costPriceAtTime: 100,
            sellPriceAtTime: 0.0,
          ),
        ],
      );

      expect(inst.materialRevenue, 0.0);
      // Same as the pre-sellPrice formula: 1000 - 200 - 200 = 600
      expect(inst.profit, 600);
    });

    test('no itemsUsed falls back to equipmentCost, materialRevenue is 0, profit unchanged', () {
      final inst = _installation(
        installationCost: 1000,
        laborCost: 100,
        equipmentCost: 300,
      );

      expect(inst.materialCost, 300);
      expect(inst.materialRevenue, 0.0);
      expect(inst.profit, 600); // 1000 - 300 - 100 + 0
    });
  });
}
