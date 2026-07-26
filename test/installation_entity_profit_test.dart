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

  group('InstallationEntity money — materials billed on top', () {
    test('amountBilled is the setup fee plus materials at sell price', () {
      final inst = _installation(
        installationCost: 1000,
        laborCost: 200,
        itemsUsed: [_item(cost: 100, sell: 150, qty: 2)],
      );

      expect(inst.money.amountBilled, 1300.0); // 1000 + 2*150
      expect(inst.money.costIncurred, 400.0); // 2*100 + 200
    });

    test('profit always equals amountBilled minus costIncurred', () {
      final cases = [
        _installation(installationCost: 1000, laborCost: 200, itemsUsed: [
          _item(cost: 100, sell: 150, qty: 2),
        ]),
        _installation(installationCost: 1000, equipmentCost: 300, laborCost: 100),
        _installation(installationCost: 2500),
        _installation(installationCost: 1000, laborCost: 4000),
      ];

      for (final inst in cases) {
        expect(inst.profit, inst.money.amountBilled - inst.money.costIncurred);
      }
    });
  });

  group('InstallationEntity profit is always knowable', () {
    test('a fee-only job reports its fee rather than null', () {
      // Was `null` (rendered 'N/A') before materials were billed on top,
      // which hid real money and made the column un-summable.
      final inst = _installation(installationCost: 3000);

      expect(inst.profit, 3000.0);
      expect(inst.hasCostData, isFalse);
      expect(inst.materialCost, isNull);
    });

    test('hasCostData is true when only laborCost is set', () {
      final inst = _installation(installationCost: 1000, laborCost: 200);

      expect(inst.hasCostData, isTrue);
      expect(inst.materialCost, isNull);
      expect(inst.profit, 800);
    });

    test('a zero fee with a marked-up BOM still turns a profit', () {
      final inst = _installation(
        installationCost: 0,
        itemsUsed: [_item(cost: 100, sell: 150)],
      );

      expect(inst.profit, 50.0);
      expect(inst.money.marginPct, closeTo(33.3333, 0.0001));
    });

    test('profit is negative when labor exceeds the margin', () {
      final inst = _installation(installationCost: 1000, laborCost: 2000);

      expect(inst.profit, -1000.0);
    });

    test('an empty but non-null itemsUsed falls back to equipmentCost', () {
      final inst = _installation(
        installationCost: 1000,
        itemsUsed: const [],
        equipmentCost: 300,
      );

      expect(inst.materialCost, 300.0);
      expect(inst.materialRevenue, 0.0);
    });
  });
}
