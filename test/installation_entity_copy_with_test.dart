import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_item_used_entity.dart';

InstallationEntity _stored() => InstallationEntity(
      id: 'i1',
      customerId: 'c1',
      customerName: 'Test Customer',
      connectionType: ConnectionType.wireless,
      installationDate: DateTime(2026, 1, 1),
      assignedEmployeeId: 'e1',
      assignedEmployeeName: 'Technician',
      installationCost: 3000,
      status: InstallationStatus.completed,
      remarks: 'original remarks',
      itemsUsed: const [
        InstallationItemUsedEntity(
          inventoryItemId: 'inv1',
          itemName: 'Router',
          quantity: 2,
          costPriceAtTime: 100,
          sellPriceAtTime: 150,
        ),
      ],
      createdAt: DateTime(2026, 1, 1),
      completedAt: DateTime(2026, 1, 2),
      equipmentCost: 750,
      laborCost: 2000,
    );

void main() {
  group('InstallationEntity.copyWith', () {
    test('preserves fields the edit dialog does not touch', () {
      // The direct regression test for the wipe: editing a job through the
      // Installations dialog used to rebuild the entity from scratch, so
      // laborCost and equipmentCost silently became null on save.
      final edited = _stored().copyWith(installationCost: 9999);

      expect(edited.laborCost, 2000.0);
      expect(edited.equipmentCost, 750.0);
      expect(edited.createdAt, DateTime(2026, 1, 1));
      expect(edited.completedAt, DateTime(2026, 1, 2));
      expect(edited.assignedEmployeeId, 'e1');
      expect(edited.installationCost, 9999.0);
    });

    test('profit is unchanged by an edit that only touches remarks', () {
      final before = _stored();
      final after = before.copyWith(remarks: 'updated remarks');

      expect(after.profit, before.profit);
      expect(after.money, before.money);
    });

    test('an explicit zero labor cost is applied, not treated as absent', () {
      expect(_stored().copyWith(laborCost: 0.0).laborCost, 0.0);
    });

    test('an empty itemsUsed list falls back to the lump-sum equipmentCost', () {
      // How the dialog clears a BOM — copyWith cannot pass null, and the
      // entity treats empty and null identically.
      final cleared = _stored().copyWith(itemsUsed: const []);

      expect(cleared.materialCost, 750.0);
      expect(cleared.materialRevenue, 0.0);
    });
  });
}
