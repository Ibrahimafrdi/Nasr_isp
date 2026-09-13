import 'package:nasr_isp/core/finance/billing_cycle.dart';
import 'package:nasr_isp/features/customers/domain/usecases/get_customers.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/get_expenses.dart';
import 'package:nasr_isp/features/payments/domain/usecases/get_all_payments.dart';

/// Returns the list of `YYYY-MM` month keys from the earliest record in the
/// system through the current month, ascending.
///
/// "Earliest record" is the minimum of:
///   • earliest customer `joinDate ?? createdAt`
///   • earliest payment `createdAt`
///   • earliest expense `date`
///
/// This range drives both the Reports page month picker and the Dashboard
/// Monthly History table — it is "all-time since launch," not a fixed window.
class GetAvailableReportMonths {
  final GetCustomers getCustomers;
  final GetAllPayments getAllPayments;
  final GetExpenses getExpenses;

  const GetAvailableReportMonths({
    required this.getCustomers,
    required this.getAllPayments,
    required this.getExpenses,
  });

  Future<List<String>> call() async {
    final results = await Future.wait([
      getCustomers(),
      getAllPayments(),
      getExpenses(),
    ]);

    final customers = (results[0] as List).cast<dynamic>();
    final payments = (results[1] as List).cast<dynamic>();
    final expenses = (results[2] as List).cast<dynamic>();

    DateTime? earliest;

    void _consider(DateTime? candidate) {
      if (candidate == null) return;
      if (earliest == null || candidate.isBefore(earliest!)) {
        earliest = candidate;
      }
    }

    for (final c in customers) {
      _consider(c.joinDate as DateTime?);
      _consider(c.createdAt as DateTime?);
    }
    for (final p in payments) {
      _consider(p.createdAt as DateTime?);
    }
    for (final e in expenses) {
      _consider(e.date as DateTime?);
    }

    final now = DateTime.now();
    if (earliest == null) {
      // No records at all — return just the current month.
      return [BillingCycle.monthKey(now)];
    }

    // Walk month by month from earliest to now.
    final months = <String>[];
    var cursor = DateTime(earliest!.year, earliest!.month);
    final end = DateTime(now.year, now.month);

    while (!cursor.isAfter(end)) {
      months.add(BillingCycle.monthKey(cursor));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return months;
  }
}
