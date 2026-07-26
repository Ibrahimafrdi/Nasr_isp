import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/installations/data/models/installation_item_used_model.dart';
import 'package:nasr_isp/features/installations/data/models/installation_model.dart';

InstallationModel _model({
  double? equipmentCost,
  double? laborCost,
  List<InstallationItemUsedModel>? itemsUsed,
}) =>
    InstallationModel(
      id: 'i1',
      customerId: 'c1',
      customerName: 'Test Customer',
      connectionType: ConnectionType.wireless,
      installationDate: DateTime(2026, 1, 1),
      installationCost: 3000,
      status: InstallationStatus.completed,
      itemsUsed: itemsUsed,
      createdAt: DateTime(2026, 1, 1),
      equipmentCost: equipmentCost,
      laborCost: laborCost,
    );

void main() {
  group('InstallationModel.toMap equipmentCost', () {
    test('omits the key entirely when the field is null', () {
      // Both update paths use a key-scoped Firestore update(), so writing an
      // unconditional null here would blow away the only material cost a
      // pre-BOM document has.
      expect(_model().toMap().containsKey('equipmentCost'), isFalse);
    });

    test('includes the key when the field is set', () {
      final map = _model(equipmentCost: 750).toMap();

      expect(map.containsKey('equipmentCost'), isTrue);
      expect(map['equipmentCost'], 750.0);
    });
  });

  group('InstallationModel.toMap laborCost', () {
    test('is always written, so an explicit zero persists', () {
      final map = _model(laborCost: 0.0).toMap();

      expect(map.containsKey('laborCost'), isTrue);
      expect(map['laborCost'], 0.0);
    });

    test('is written when set', () {
      expect(_model(laborCost: 2000).toMap()['laborCost'], 2000.0);
    });
  });

  group('InstallationModel round trip', () {
    test('preserves laborCost, equipmentCost and BOM sell prices', () {
      final original = _model(
        equipmentCost: 750,
        laborCost: 2000,
        itemsUsed: const [
          InstallationItemUsedModel(
            inventoryItemId: 'inv1',
            itemName: 'Router',
            quantity: 2,
            costPriceAtTime: 100,
            sellPriceAtTime: 150,
          ),
        ],
      );

      final restored = InstallationModel.fromMap(original.toMap(), 'i1');

      expect(restored.laborCost, 2000.0);
      expect(restored.equipmentCost, 750.0);
      expect(restored.itemsUsed!.single.sellPriceAtTime, 150.0);
      expect(restored.profit, original.profit);
    });

    test('a null equipmentCost survives the omitted key as null', () {
      final restored =
          InstallationModel.fromMap(_model(laborCost: 500).toMap(), 'i1');

      expect(restored.equipmentCost, isNull);
      expect(restored.laborCost, 500.0);
    });
  });
}
