import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/inventory/data/models/stock_issue_model.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_issue_entity.dart';

void main() {
  final issueDate = DateTime(2026, 11, 4);

  StockIssueModel issue({int quantity = 2, String? towerName = 'Tower A'}) =>
      StockIssueModel(
        id: 'issue-1',
        itemId: 'item-1',
        itemName: 'Outdoor radio',
        quantity: quantity,
        unitCost: 1250,
        purpose: StockIssuePurpose.tower,
        towerName: towerName,
        notes: 'Sector 2',
        date: issueDate,
        issuedBy: 'admin-1',
        createdAt: issueDate,
      );

  group('StockIssueModel', () {
    test('serializes the issue record fields to Firestore', () {
      final data = issue().toFirestore();

      expect(data['itemId'], 'item-1');
      expect(data['itemName'], 'Outdoor radio');
      expect(data['quantity'], 2);
      expect(data['unitCost'], 1250);
      expect(data['purpose'], 'tower');
      expect(data['towerName'], 'Tower A');
      expect(data['notes'], 'Sector 2');
      expect((data['date'] as Timestamp).toDate(), issueDate);
      expect(data['issuedBy'], 'admin-1');
      expect((data['createdAt'] as Timestamp).toDate(), issueDate);
    });

    test('maps Firestore fields into an entity', () {
      final original = issue();
      final restored = StockIssueModel.fromMap(
        original.toFirestore(),
        id: original.id,
      );

      expect(restored.id, original.id);
      expect(restored.toEntity().itemName, original.itemName);
      expect(restored.toEntity().unitCost, original.unitCost);
      expect(restored.toEntity().purpose, StockIssuePurpose.tower);
    });
  });

  group('StockIssueEntity validation', () {
    test('rejects a zero or negative quantity', () {
      expect(
        () => issue(quantity: 0).toEntity().validate(),
        throwsArgumentError,
      );
      expect(
        () => issue(quantity: -1).toEntity().validate(),
        throwsArgumentError,
      );
    });

    test('requires a tower name only for tower issues', () {
      expect(
        () => issue(towerName: '  ').toEntity().validate(),
        throwsArgumentError,
      );
      expect(
        () => StockIssueEntity(
          id: 'issue-2',
          itemId: 'item-1',
          itemName: 'Outdoor radio',
          quantity: 1,
          unitCost: 1250,
          purpose: StockIssuePurpose.other,
          date: issueDate,
          issuedBy: 'admin-1',
        ).validate(),
        returnsNormally,
      );
    });
  });
}
