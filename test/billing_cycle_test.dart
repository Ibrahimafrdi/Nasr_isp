import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/finance/billing_cycle.dart';

void main() {
  group('addMonths', () {
    test(
      'keeps the anniversary day for an ordinary date and sets 12 PM cutoff',
      () {
        expect(
          BillingCycle.addMonths(DateTime(2026, 3, 15)),
          DateTime(2026, 4, 15, 12, 0),
        );
      },
    );

    test('clamps instead of rolling over at month end', () {
      expect(
        BillingCycle.addMonths(DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28, 12, 0),
      );
      expect(
        BillingCycle.addMonths(DateTime(2026, 3, 31)),
        DateTime(2026, 4, 30, 12, 0),
      );
      expect(
        BillingCycle.addMonths(DateTime(2026, 5, 31)),
        DateTime(2026, 6, 30, 12, 0),
      );
    });

    test('clamps to Feb 29 in a leap year', () {
      expect(
        BillingCycle.addMonths(DateTime(2028, 1, 30)),
        DateTime(2028, 2, 29, 12, 0),
      );
    });

    test('rolls the year over in December', () {
      expect(
        BillingCycle.addMonths(DateTime(2026, 12, 5)),
        DateTime(2027, 1, 5, 12, 0),
      );
    });

    test('a month-end customer never drifts past the 28th', () {
      var date = DateTime(2026, 1, 31);
      for (var i = 0; i < 12; i++) {
        date = BillingCycle.addMonths(date);
      }
      expect(date, DateTime(2027, 1, 28, 12, 0));
    });

    test('normalizes any input time to the 12:00 PM cutoff', () {
      final result = BillingCycle.addMonths(DateTime(2026, 3, 15, 23, 59, 59));
      expect(result, DateTime(2026, 4, 15, 12, 0));
    });
  });

  group('monthKey', () {
    test('zero-pads single-digit months', () {
      expect(BillingCycle.monthKey(DateTime(2026, 3, 15)), '2026-03');
      expect(BillingCycle.monthKey(DateTime(2026, 11, 1)), '2026-11');
    });
  });

  group('expiry predicates — Jazz 12:00 PM cutoff alignment', () {
    final due = DateTime(2026, 8, 6);

    test(
      'before 12:00 PM on due date: customer is NOT yet expired (Due today)',
      () {
        final morning = DateTime(2026, 8, 6, 11, 30);
        expect(BillingCycle.isExpird(due, morning), isFalse);
        expect(BillingCycle.dayUntilDue(due, morning), 0);
      },
    );

    test(
      'at exactly 12:00 PM on due date: customer expires (matches Jazz cutoff)',
      () {
        final noon = DateTime(2026, 8, 6, 12, 0);
        expect(BillingCycle.isExpird(due, noon), isTrue);
        expect(BillingCycle.dayUntilDue(due, noon), -1);
      },
    );

    test('after 12:00 PM on due date: customer is expired', () {
      final afternoon = DateTime(2026, 8, 6, 14, 30);
      expect(BillingCycle.isExpird(due, afternoon), isTrue);
      expect(BillingCycle.dayUntilDue(due, afternoon), -1);
    });

    test('the day after the due date is expired and overdue', () {
      final nextDay = DateTime(2026, 8, 7, 9, 0);
      expect(BillingCycle.isExpird(due, nextDay), isTrue);
      expect(BillingCycle.dayUntilDue(due, nextDay), -1);
    });

    test('the renewal window opens exactly 7 days out', () {
      final morning = DateTime(2026, 8, 6, 10, 0);
      expect(
        BillingCycle.isDueForRenewal(DateTime(2026, 8, 13), morning),
        isTrue,
      );
      expect(
        BillingCycle.isDueForRenewal(DateTime(2026, 8, 14), morning),
        isFalse,
      );
    });

    test('an expired customer is always due for renewal', () {
      final morning = DateTime(2026, 8, 6, 10, 0);
      expect(
        BillingCycle.isDueForRenewal(DateTime(2026, 1, 1), morning),
        isTrue,
      );
    });
  });

  group('effectiveDueDate', () {
    test('prefers the stored due date', () {
      expect(
        BillingCycle.effectiveDueDate(
          nextDueDate: DateTime(2026, 9, 1),
          createdAt: DateTime(2026, 1, 1),
        ),
        DateTime(2026, 9, 1),
      );
    });

    test('falls back to one month after creation at 12 PM, clamped', () {
      expect(
        BillingCycle.effectiveDueDate(createdAt: DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28, 12, 0),
      );
    });

    test('is null when neither date exists', () {
      expect(BillingCycle.effectiveDueDate(), isNull);
    });
  });
}
