import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';

/// Builds the WhatsApp text sent to a customer whose subscription has lapsed
/// or is about to.
///
/// Pure Dart on purpose: no Flutter, no Firestore, so the wording can be unit
/// tested and edited in one place. The expiry rules come from
/// [CustomerEntity] / [BillingCycle], so a reminder can never disagree with
/// the "Expired" and "Expiring Soon" badges on the Customers page.
class RenewalReminder {
  const RenewalReminder._();

  /// Whether a reminder makes sense for [customer] at [now]: on service and
  /// either expired, due today, or inside the renewal window.
  static bool isReminderDue(CustomerEntity customer, DateTime now) =>
      customer.isDueForRenewalAt(now);

  /// The message text for [customer], or null when there is nothing to remind
  /// about (inactive customer, or no usable due date).
  static String? message({
    required CustomerEntity customer,
    required DateTime now,
    String packageName = '',
    String companyName = '',
    String companyPhone = '',
  }) {
    final due = customer.billingDueDate;
    if (due == null) return null;

    final name = customer.name.trim().isEmpty ? 'Customer' : customer.name.trim();
    final dueText = DateTimeUtils.formatDate(due);
    final amount = DateTimeUtils.formatCurrency(customer.monthlyBill);
    final plan = packageName.trim().isEmpty ? 'internet package' : '$packageName package';

    final String status;
    if (customer.isExpiredAt(now)) {
      status = 'Your $plan expired on $dueText.';
    } else {
      final days = BillingCycle.dayUntilDue(due, now);
      if (days <= 0) {
        status = 'Your $plan expires today at 12:00 PM.';
      } else if (days == 1) {
        status = 'Your $plan expires tomorrow ($dueText) at 12:00 PM.';
      } else {
        status = 'Your $plan expires in $days days, on $dueText.';
      }
    }

    final call = companyPhone.trim().isEmpty ? '' : ' For any help call $companyPhone.';
    final sender = companyName.trim().isEmpty ? '' : '\n$companyName';

    return 'Assalam o Alaikum $name,\n'
        '$status '
        'Please pay $amount to renew and keep your connection running.$call\n'
        'Thank you.$sender';
  }
}
