import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/customers/data/models/customer_model.dart';
import 'package:nasr_isp/features/customers/domain/usecases/set_customer_status.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

/// Opens the right on/off-service dialog for [customer] and dispatches the
/// resulting [SetCustomerStatusEvent].
///
/// Deactivating only needs a yes/no. Reactivating has to ask which billing
/// cycle the customer returns on, so it gets its own dialog — see
/// [_ReactivateCustomerDialog].
///
/// Resolves to true when an event was dispatched, false when the operator
/// cancelled. Callers holding their own snapshot of the customer use this to
/// decide whether they need to re-read it.
Future<bool> showCustomerStatusDialog(
  BuildContext context, {
  required CustomerModel customer,
  DateTime Function() clock = DateTime.now,
}) async {
  // Resolved before any await: the dialog route does not own CustomersBloc,
  // and the calling page's element may be gone by the time we dispatch.
  final bloc = context.read<CustomersBloc>();

  if (customer.isActive) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Deactivate Customer',
        message:
            'Deactivate ${customer.name}? Their subscription stops being '
            'tracked — no due date, no renewal reminders, and they drop out '
            'of the expired and expiring counts. Their record and payment '
            'history are kept, and you can reactivate them at any time.',
        confirmLabel: 'Deactivate',
        isDestructive: true,
        onConfirm: () {
          Navigator.of(ctx).pop(true);
          bloc.add(
            SetCustomerStatusEvent(customer: customer, active: false),
          );
        },
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    return confirmed ?? false;
  }

  final reactivated = await showDialog<bool>(
    context: context,
    builder: (ctx) => _ReactivateCustomerDialog(
      customer: customer,
      customersBloc: bloc,
      clock: clock,
    ),
  );
  return reactivated ?? false;
}

/// What to tell the operator after a status change lands.
class StatusChangeReport {
  final String message;

  /// True when the operator needs to do something about it — a fresh cycle
  /// that couldn't be billed leaves an unbilled month behind.
  final bool isWarning;

  const StatusChangeReport(this.message, {this.isWarning = false});
}

/// Turns a completed [CustomerStatusOutcome] into operator-facing wording.
///
/// A fresh-cycle reactivation is the case worth reporting carefully: it can
/// silently produce no charge, and an unbilled month that nobody is told about
/// is exactly the hole this billing raised the charge to close.
StatusChangeReport describeStatusChange(CustomerStatusOutcome outcome) {
  final name = outcome.customer.name;

  if (!outcome.customer.isActive) {
    return StatusChangeReport(
      '$name deactivated. Their subscription is no longer tracked for renewal.',
    );
  }

  switch (outcome.unbilledReason) {
    case UnbilledReason.noMonthlyBill:
      return StatusChangeReport(
        '$name reactivated, but nothing was billed — no monthly bill is set. '
        'Assign a package or a rate, then collect via Renew.',
        isWarning: true,
      );
    case UnbilledReason.monthAlreadyBilled:
      return StatusChangeReport(
        '$name reactivated. This month was already billed, so no second '
        'charge was raised.',
        isWarning: true,
      );
    case null:
      break;
  }

  final charge = outcome.charge;
  if (charge == null) {
    return StatusChangeReport('$name reactivated on their existing cycle.');
  }
  return StatusChangeReport(
    '$name reactivated. '
    '${DateTimeUtils.formatCurrency(charge.amount)} billed for the resumed '
    'month — outstanding until collected.',
  );
}

/// Asks which billing cycle a returning customer comes back on.
///
/// The two answers differ by a month of revenue, so neither is a safe silent
/// default: resuming bills the customer for the period they were away,
/// starting fresh writes it off. The dialog states the resulting expiry for
/// each so the operator picks on the number rather than the wording.
class _ReactivateCustomerDialog extends StatefulWidget {
  final CustomerModel customer;
  final CustomersBloc customersBloc;
  final DateTime Function() clock;

  const _ReactivateCustomerDialog({
    required this.customer,
    required this.customersBloc,
    required this.clock,
  });

  @override
  State<_ReactivateCustomerDialog> createState() =>
      _ReactivateCustomerDialogState();
}

class _ReactivateCustomerDialogState extends State<_ReactivateCustomerDialog> {
  ReactivationCycle _cycle = ReactivationCycle.resumeExisting;

  @override
  void initState() {
    super.initState();
    // With nothing stored to resume, "keep the existing expiry" would put the
    // customer back with no due date at all and no way to reach one except a
    // renewal. Start them on a real cycle instead.
    if (widget.customer.effectiveDueDate == null) {
      _cycle = ReactivationCycle.startFresh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = BillingCycle.dateOnly(widget.clock());
    final existingDue = widget.customer.effectiveDueDate;
    final freshDue = BillingCycle.addMonths(now);

    final String resumeSubtitle;
    if (existingDue == null) {
      resumeSubtitle = 'No expiry on record for this customer.';
    } else {
      final days = BillingCycle.daysUntilDue(existingDue, now);
      final standing = days < 0
          ? 'already overdue by ${-days} days'
          : (days == 0 ? 'due today' : 'due in $days days');
      resumeSubtitle =
          'Expiry stays ${DateTimeUtils.formatDate(existingDue)} — $standing. '
          'Collect the arrears with Renew.';
    }

    return AlertDialog(
      title: const Text('Reactivate Customer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Put ${widget.customer.name} back on service. Which billing cycle '
            'do they return on?',
            style: const TextStyle(fontSize: 13, color: AppTheme.darkGray),
          ),
          const SizedBox(height: 12),
          RadioGroup<ReactivationCycle>(
            groupValue: _cycle,
            onChanged: (v) => setState(() => _cycle = v!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RadioListTile<ReactivationCycle>(
                  value: ReactivationCycle.resumeExisting,
                  // Nothing to resume when no expiry was ever stored.
                  enabled: existingDue != null,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'Resume the existing cycle',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    resumeSubtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ),
                RadioListTile<ReactivationCycle>(
                  value: ReactivationCycle.startFresh,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'Start a fresh cycle from today',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Expiry moves to ${DateTimeUtils.formatDate(freshDue)}. '
                    'The time spent inactive is written off, and '
                    '${DateTimeUtils.formatCurrency(widget.customer.monthlyBill)} '
                    'is billed now for the resumed month — the customer '
                    'returns owing it.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop(true);
            widget.customersBloc.add(
              SetCustomerStatusEvent(
                customer: widget.customer,
                active: true,
                cycle: _cycle,
              ),
            );
          },
          child: const Text('Reactivate'),
        ),
      ],
    );
  }
}
