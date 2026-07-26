import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/finance/money_line.dart';

MoneyLine _line({double billed = 0, double cost = 0}) =>
    MoneyLine(amountBilled: billed, costIncurred: cost);

void main() {
  group('MoneyLine profit', () {
    test('profit is billed minus cost', () {
      expect(_line(billed: 1300, cost: 400).profit, 900.0);
    });

    test('profit is negative when cost exceeds what was billed', () {
      expect(_line(billed: 500, cost: 800).profit, -300.0);
    });

    test('isZero distinguishes an empty line from a break-even one', () {
      expect(_line().isZero, isTrue);
      expect(_line(billed: 500, cost: 500).isZero, isFalse);
    });
  });

  group('MoneyLine marginPct', () {
    test('uses amountBilled as the denominator, not the profit base', () {
      // 900 / 1300, i.e. materials billed are part of the denominator.
      expect(_line(billed: 1300, cost: 400).marginPct, closeTo(69.2307, 0.0001));
    });

    test('is 100 when nothing was spent', () {
      expect(_line(billed: 1000).marginPct, 100.0);
    });

    test('is null when nothing was billed, even with real costs', () {
      expect(_line(cost: 500).marginPct, isNull);
      expect(_line().marginPct, isNull);
    });

    test('is null for a negative amountBilled', () {
      expect(_line(billed: -100, cost: 50).marginPct, isNull);
    });
  });

  group('MoneyLine summation', () {
    test('operator + adds both components', () {
      expect(
        _line(billed: 100, cost: 40) + _line(billed: 200, cost: 60),
        const MoneyLine(amountBilled: 300, costIncurred: 100),
      );
    });

    test('zero is the additive identity', () {
      final line = _line(billed: 750, cost: 125);
      expect(MoneyLine.zero + line, line);
      expect(line + MoneyLine.zero, line);
    });

    test('sum of an empty iterable is zero', () {
      expect(MoneyLine.sum(const []), MoneyLine.zero);
    });

    test('sum equals the arithmetic sum of each line profit', () {
      // The anti-drift invariant: an aggregate card built with sum() can never
      // disagree with the rows beneath it.
      final lines = [
        _line(billed: 1300, cost: 400),
        _line(billed: 500, cost: 800), // loss-making
        _line(billed: 3000), // no costs logged
        _line(cost: 250), // billed nothing, spent money
      ];

      expect(
        MoneyLine.sum(lines).profit,
        lines.fold<double>(0.0, (sum, l) => sum + l.profit),
      );
      expect(MoneyLine.sum(lines).profit, 3350.0);
    });
  });
}
