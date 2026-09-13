/// Month arithmetic for the prepaid subscription cycle.
///
/// One home for the three rules that were previously re-derived at every call
/// site — and derived inconsistently:
///
///   * how far a renewal pushes the expiry date,
///   * which `YYYY-MM` bucket a payment belongs to,
///   * what to show when a legacy customer has no stored due date.
class BillingCycle {
  const BillingCycle._();

  /// How many days before expiry the Renew action becomes available. Matches
  /// the "Expiring Soon" threshold used by the dashboard alert and the
  /// customer status filter, so the CTA is live for every customer those
  /// surfaces tell the operator to chase.
  static const int renewalWindowDays = 7;

  /// [months] after [from], clamped to the last day of the target month.
  ///
  /// `DateTime(y, m + 1, d)` silently rolls over — Jan 31 becomes Mar 2, or
  /// Mar 3 in a leap year — which would walk a month-end customer's
  /// anniversary forward a couple of days on every single renewal. Clamping
  /// keeps Jan 31 → Feb 28/29 → Mar 28, which never drifts past the 28th but
  /// also never overshoots into the following month.
  static DateTime addMonths(DateTime from, [int months = 1]) {
    assert(months >= 0, 'addMonths only moves the cycle forward');
    final zeroBased = from.month - 1 + months;
    final year = from.year + zeroBased ~/ 12;
    final month = zeroBased % 12 + 1;
    // Day 0 of the *next* month is the last day of this one.
    final lastDayOfTarget = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, from.day < lastDayOfTarget ? from.day : lastDayOfTarget);
  }

  /// The `YYYY-MM` bucket a renewal belongs to. This is half of the
  /// `(customerId, billingMonth)` key that keeps one subscription charge per
  /// customer per month.
  static String monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  /// Converts a `YYYY-MM` string into a readable label (e.g. `'2026-09'` -> `'September 2026'`).
  static String formatMonthKey(String key) {
    final parts = key.split('-');
    if (parts.length == 2) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (year != null && month != null && month >= 1 && month <= 12) {
        const monthNames = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        return '${monthNames[month - 1]} $year';
      }
    }
    return key;
  }

  /// Midnight on [date] — the granularity every due-date comparison uses, so
  /// that "expired" never depends on the time of day a record was written.
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// The due date to act on: the stored [nextDueDate], or one month after
  /// [createdAt] for legacy records that never had one written.
  ///
  /// Display and eligibility must agree on this, so both read it from here.
  /// The fallback is never written back to Firestore — only a renewal writes
  /// a due date.
  static DateTime? effectiveDueDate({
    DateTime? nextDueDate,
    DateTime? createdAt,
  }) {
    if (nextDueDate != null) return nextDueDate;
    if (createdAt != null) return addMonths(createdAt);
    return null;
  }

  /// Whole days from [now] to [due]. Negative once the subscription has
  /// lapsed, zero on the due date itself.
  static int daysUntilDue(DateTime due, DateTime now) =>
      dateOnly(due).difference(dateOnly(now)).inDays;

  /// True once the paid-for period has fully elapsed.
  ///
  /// The due date itself is NOT expired: the customer has been billed through
  /// the end of that day. This is what makes the "Due Today" badge and the
  /// expired count agree.
  static bool isExpired(DateTime due, DateTime now) => daysUntilDue(due, now) < 0;

  /// True when the operator should be offered the Renew action — expired, due
  /// today, or inside the [renewalWindowDays] warning window.
  static bool isDueForRenewal(DateTime due, DateTime now) =>
      daysUntilDue(due, now) <= renewalWindowDays;
}
