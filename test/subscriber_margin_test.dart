import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/finance/money_line.dart';
import 'package:nasr_isp/core/finance/subscriber_margin.dart';

SubscriberMargin _margin({
  double bill = 3000,
  double cost = 941,
  required SubscriberCostBasis basis,
}) =>
    SubscriberMargin(
      money: MoneyLine(amountBilled: bill, costIncurred: cost),
      basis: basis,
    );

void main() {
  group('SubscriberMargin reliability', () {
    test('packageKnown is reliable and not flagged missing', () {
      final margin = _margin(basis: SubscriberCostBasis.packageKnown);
      expect(margin.isReliable, isTrue);
      expect(margin.isPackageMissing, isFalse);
    });

    test('packageUnresolved is unreliable and flagged missing', () {
      final margin = _margin(
        cost: 0,
        basis: SubscriberCostBasis.packageUnresolved,
      );
      expect(margin.isReliable, isFalse);
      expect(margin.isPackageMissing, isTrue);
    });

    test('noPackageAssigned is unreliable but not flagged missing', () {
      // An ad-hoc bill with no package is expected, not a data problem.
      final margin = _margin(
        cost: 0,
        basis: SubscriberCostBasis.noPackageAssigned,
      );
      expect(margin.isReliable, isFalse);
      expect(margin.isPackageMissing, isFalse);
    });
  });

  group('SubscriberMargin money', () {
    test('profit is monthlyBill minus costPrice', () {
      expect(
        _margin(basis: SubscriberCostBasis.packageKnown).money.profit,
        2059.0,
      );
    });

    test('an unresolved package yields a 100% margin, now flagged', () {
      // The symptom the basis flag exists to guard: a deleted package falls
      // back to a zero cost price, so the margin looks perfect.
      final margin = _margin(
        cost: 0,
        basis: SubscriberCostBasis.packageUnresolved,
      );
      expect(margin.money.marginPct, 100.0);
      expect(margin.isPackageMissing, isTrue);
    });
  });
}
