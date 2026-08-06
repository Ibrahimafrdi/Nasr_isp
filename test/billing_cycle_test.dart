import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/finance/billing_cycle.dart';

void main() {
  group('addMonths', () {
    test('keeps the anniversary day for an ordinary date', () {
      expect(BillingCycle.addMonths(DateTime(2026, 3, 15)), DateTime(2026, 4, 15));
    });

    test('clamps instead of rolling over at month end', () {
      // The regression this class exists for: DateTime(2026, 2, 31) silently
      // becomes Mar 3, walking a month-end customer's anniversary forward on
      // every renewal.
      expect(BillingCycle.addMonths(DateTime(2026, 1, 31)), DateTime(2026, 2, 28));
      expect(BillingCycle.addMonths(DateTime(2026, 3, 31)), DateTime(2026, 4, 30));
      expect(BillingCycle.addMonths(DateTime(2026, 5, 31)), DateTime(2026, 6, 30));
    });

    test('clamps to Feb 29 in a leap year', () {
      expect(BillingCycle.addMonths(DateTime(2028, 1, 30)), DateTime(2028, 2, 29));
    });

    test('rolls the year over in December', () {
      expect(BillingCycle.addMonths(DateTime(2026, 12, 5)), DateTime(2027, 1, 5));
    });

    test('a month-end customer never drifts past the 28th', () {
      // Twelve consecutive renewals from Jan 31. Pre-clamp this walked to
      // March, then May, and so on.
      var date = DateTime(2026, 1, 31);
      for (var i = 0; i < 12; i++) {
        date = BillingCycle.addMonths(date);
      }
      expect(date, DateTime(2027, 1, 28));
    });

    test('drops any time component so comparisons are date-only', () {
      final result = BillingCycle.addMonths(DateTime(2026, 3, 15, 23, 59, 59));
      expect(result, DateTime(2026, 4, 15));
    });
  });

  group('monthKey', () {
    test('zero-pads single-digit months', () {
      expect(BillingCycle.monthKey(DateTime(2026, 3, 15)), '2026-03');
      expect(BillingCycle.monthKey(DateTime(2026, 11, 1)), '2026-11');
    });
  });

  group('expiry predicates', () {
    final now = DateTime(2026, 8, 6, 14, 30);

    test('the due date itself is not yet expired', () {
      // The customer is billed through the end of the due date, which is what
      // keeps the "Due Today" badge and the expired count in agreement.
      expect(BillingCycle.isExpired(DateTime(2026, 8, 6), now), isFalse);
      expect(BillingCycle.daysUntilDue(DateTime(2026, 8, 6), now), 0);
    });

    test('the day after the due date is expired', () {
      expect(BillingCycle.isExpired(DateTime(2026, 8, 5), now), isTrue);
      expect(BillingCycle.daysUntilDue(DateTime(2026, 8, 5), now), -1);
    });

    test('time of day never decides expiry', () {
      final earlyMorning = DateTime(2026, 8, 6, 0, 1);
      final lateNight = DateTime(2026, 8, 6, 23, 59);
      for (final instant in [earlyMorning, lateNight]) {
        expect(BillingCycle.isExpired(DateTime(2026, 8, 6), instant), isFalse);
      }
    });

    test('the renewal window opens exactly 7 days out', () {
      expect(BillingCycle.isDueForRenewal(DateTime(2026, 8, 13), now), isTrue);
      expect(BillingCycle.isDueForRenewal(DateTime(2026, 8, 14), now), isFalse);
    });

    test('an expired customer is always due for renewal', () {
      expect(BillingCycle.isDueForRenewal(DateTime(2026, 1, 1), now), isTrue);
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

    test('falls back to one month after creation, clamped', () {
      expect(
        BillingCycle.effectiveDueDate(createdAt: DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28),
      );
    });

    test('is null when neither date exists', () {
      expect(BillingCycle.effectiveDueDate(), isNull);
    });
  });
}
