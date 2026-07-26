import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/money_line.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_item_used_entity.dart';
import 'package:nasr_isp/features/installations/domain/utils/installation_aggregates.dart';

InstallationEntity _installation({
  String id = 'i1',
  double installationCost = 0,
  List<InstallationItemUsedEntity>? itemsUsed,
  double? equipmentCost,
  double? laborCost,
  InstallationStatus status = InstallationStatus.completed,
  DateTime? createdAt,
  DateTime? completedAt,
}) {
  return InstallationEntity(
    id: id,
    customerId: 'c1',
    customerName: 'Test Customer',
    connectionType: ConnectionType.wireless,
    installationDate: DateTime(2026, 1, 1),
    installationCost: installationCost,
    status: status,
    itemsUsed: itemsUsed,
    createdAt: createdAt ?? DateTime(2026, 7, 10),
    completedAt: completedAt,
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

/// A deliberately mixed set: BOM job, legacy lump-sum job, fee-only job, and
/// a loss-maker.
List<InstallationEntity> _mixedJobs() => [
      _installation(
        id: 'bom',
        installationCost: 3000,
        laborCost: 500,
        itemsUsed: [_item(cost: 100, sell: 150, qty: 2)],
      ),
      _installation(id: 'legacy', installationCost: 1000, equipmentCost: 300),
      _installation(id: 'feeOnly', installationCost: 2500),
      _installation(id: 'loss', installationCost: 1000, laborCost: 4000),
    ];

void main() {
  group('installationsMoney', () {
    test('profit equals the sum of the per-row profits', () {
      // The regression this refactor exists for: an aggregate card must equal
      // the sum of the rows shown beneath it.
      final jobs = _mixedJobs();

      expect(
        installationsMoney(jobs).profit,
        jobs.fold<double>(0.0, (sum, i) => sum + i.profit),
      );
    });

    test('amountBilled includes material revenue, not just setup fees', () {
      // Materials are billed on top of the fee, so revenue must exceed the
      // sum of installationCost wherever a BOM exists. This is the exact bug
      // that made profit larger than "billed" on the dashboard.
      final jobs = _mixedJobs();
      final feesOnly = jobs.fold<double>(0.0, (s, i) => s + i.installationCost);

      expect(installationsMoney(jobs).amountBilled, greaterThan(feesOnly));
      expect(installationsMoney(jobs).amountBilled, feesOnly + 300.0);
    });

    test('revenue minus cost equals profit by construction', () {
      final totals = installationsMoney(_mixedJobs());
      expect(totals.amountBilled - totals.costIncurred, totals.profit);
    });

    test('an empty list is MoneyLine.zero', () {
      expect(installationsMoney(const []), MoneyLine.zero);
    });

    test('marginPct is null when nothing was billed at all', () {
      final jobs = [_installation(installationCost: 0, laborCost: 500)];
      expect(installationsMoney(jobs).marginPct, isNull);
    });
  });

  group('isFinanciallyCountable', () {
    test('only completed jobs count', () {
      expect(isFinanciallyCountable(InstallationStatus.completed), isTrue);
      expect(isFinanciallyCountable(InstallationStatus.pending), isFalse);
      expect(isFinanciallyCountable(InstallationStatus.inProgress), isFalse);
      expect(isFinanciallyCountable(InstallationStatus.cancelled), isFalse);
    });
  });

  group('completedInMonth', () {
    final july = DateTime(2026, 7, 15);

    test('excludes pending, in-progress and cancelled jobs', () {
      final jobs = [
        _installation(id: 'a', status: InstallationStatus.pending),
        _installation(id: 'b', status: InstallationStatus.inProgress),
        _installation(id: 'c', status: InstallationStatus.cancelled),
        _installation(id: 'd', status: InstallationStatus.completed),
      ];

      final result = completedInMonth(jobs, july);
      expect(result.map((i) => i.id), ['d']);
    });

    test('a cancelled job contributes nothing to the money aggregate', () {
      final jobs = [
        _installation(
          id: 'cancelled',
          installationCost: 9999,
          status: InstallationStatus.cancelled,
          itemsUsed: [_item(cost: 100, sell: 150, qty: 5)],
        ),
      ];

      expect(installationsMoney(completedInMonth(jobs, july)), MoneyLine.zero);
    });

    test('buckets by completedAt when it is present', () {
      final jobs = [
        _installation(
          id: 'lateComplete',
          createdAt: DateTime(2026, 5, 2),
          completedAt: DateTime(2026, 7, 3),
        ),
      ];

      expect(completedInMonth(jobs, july).map((i) => i.id), ['lateComplete']);
    });

    test('falls back to createdAt when completedAt is missing', () {
      final jobs = [
        _installation(id: 'legacyDoc', createdAt: DateTime(2026, 7, 20)),
      ];

      expect(completedInMonth(jobs, july).map((i) => i.id), ['legacyDoc']);
    });

    test('excludes a job completed in the same month of another year', () {
      final jobs = [
        _installation(
          id: 'lastYear',
          createdAt: DateTime(2025, 7, 1),
          completedAt: DateTime(2025, 7, 5),
        ),
      ];

      expect(completedInMonth(jobs, july), isEmpty);
    });
  });
}
