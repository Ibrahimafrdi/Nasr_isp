import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/finance/material_totals.dart';

class _Line {
  const _Line(this.qty, this.cost, this.sell);
  final int qty;
  final double cost;
  final double sell;
}

MaterialTotals _ofLines(List<_Line> lines) => MaterialTotals.of<_Line>(
      lines,
      quantity: (l) => l.qty,
      unitCost: (l) => l.cost,
      sellPrice: (l) => l.sell,
    );

void main() {
  group('MaterialTotals.of', () {
    test('sums qty times cost and qty times sell across lines', () {
      final totals = _ofLines(const [
        _Line(2, 100, 150),
        _Line(3, 50, 80),
      ]);

      expect(totals.cost, 350.0); // 2*100 + 3*50
      expect(totals.revenue, 540.0); // 2*150 + 3*80
      expect(totals.isRecorded, isTrue);
    });

    test('an empty iterable is not recorded', () {
      expect(_ofLines(const []), MaterialTotals.none);
      expect(_ofLines(const []).isRecorded, isFalse);
    });
  });

  group('MaterialTotals.fromRows', () {
    test('produces the same totals as of() over equivalent typed lines', () {
      // Guarantees a live form preview and the saved record cannot diverge.
      const rows = [
        {'qty': 2, 'unitCost': 100.0, 'sellPrice': 150.0},
        {'qty': 3, 'unitCost': 50.0, 'sellPrice': 80.0},
      ];

      expect(
        MaterialTotals.fromRows(rows),
        _ofLines(const [_Line(2, 100, 150), _Line(3, 50, 80)]),
      );
    });

    test('reads a missing sellPrice key as zero rather than throwing', () {
      final totals = MaterialTotals.fromRows(const [
        {'qty': 2, 'unitCost': 100.0},
      ]);

      expect(totals.cost, 200.0);
      expect(totals.revenue, 0.0);
      expect(totals.isRecorded, isTrue);
    });

    test('tolerates an int stored where a double is expected', () {
      final totals = MaterialTotals.fromRows(const [
        {'qty': 2, 'unitCost': 100, 'sellPrice': 150},
      ]);

      expect(totals.cost, 200.0);
      expect(totals.revenue, 300.0);
    });

    test('an empty row list is not recorded', () {
      expect(MaterialTotals.fromRows(const []), MaterialTotals.none);
    });
  });

  group('MaterialTotals.lumpSum', () {
    test('null equipment cost means nothing was recorded', () {
      expect(MaterialTotals.lumpSum(null), MaterialTotals.none);
      expect(MaterialTotals.lumpSum(null).isRecorded, isFalse);
    });

    test('an explicit zero is recorded, unlike null', () {
      final totals = MaterialTotals.lumpSum(0.0);
      expect(totals.isRecorded, isTrue);
      expect(totals.cost, 0.0);
    });

    test('carries no revenue — a lump sum has no per-item sell price', () {
      expect(MaterialTotals.lumpSum(300.0).revenue, 0.0);
      expect(MaterialTotals.lumpSum(300.0).cost, 300.0);
    });
  });

  group('MaterialTotals.markup', () {
    test('is revenue minus cost', () {
      expect(_ofLines(const [_Line(2, 100, 150)]).markup, 100.0);
    });

    test('is negative when items are sold below cost', () {
      expect(_ofLines(const [_Line(1, 200, 150)]).markup, -50.0);
    });
  });
}
