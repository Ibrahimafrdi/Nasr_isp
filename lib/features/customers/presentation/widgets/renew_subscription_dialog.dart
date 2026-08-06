import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/input_formatters.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';

/// Collects a month's subscription payment and extends the customer's expiry.
///
/// Deliberately narrower than the general "add payment" form it replaces: the
/// customer is fixed, the amount is anchored to their monthly bill, and the
/// new expiry is shown before the operator commits. There is nothing here to
/// pick wrong.
Future<void> showRenewSubscriptionDialog(
  BuildContext context, {
  required CustomerModel customer,
  required String packageName,
  DateTime Function() clock = DateTime.now,
}) {
  final isMobileDialog = Responsive.isMobile(context);
  return showDialog<void>(
    context: context,
    useSafeArea: !isMobileDialog,
    builder: (_) => _RenewSubscriptionDialog(
      customer: customer,
      packageName: packageName,
      // The parent's context owns CustomersBloc; the dialog route does not.
      customersBloc: context.read<CustomersBloc>(),
      clock: clock,
      isMobileDialog: isMobileDialog,
    ),
  );
}

class _RenewSubscriptionDialog extends StatefulWidget {
  final CustomerModel customer;
  final String packageName;
  final CustomersBloc customersBloc;
  final DateTime Function() clock;
  final bool isMobileDialog;

  const _RenewSubscriptionDialog({
    required this.customer,
    required this.packageName,
    required this.customersBloc,
    required this.clock,
    required this.isMobileDialog,
  });

  @override
  State<_RenewSubscriptionDialog> createState() =>
      _RenewSubscriptionDialogState();
}

class _RenewSubscriptionDialogState extends State<_RenewSubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late DateTime _renewalDate;
  String _method = 'cash';
  String _notes = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _renewalDate = BillingCycle.dateOnly(widget.clock());
    _amountController = TextEditingController(
      text: widget.customer.monthlyBill.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _enteredAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0.0;

  DateTime get _newExpiry => BillingCycle.addMonths(_renewalDate);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    // Resolved before the await: after Navigator.pop this State is deactivated
    // and its context can no longer look an ancestor up.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final bloc = widget.customersBloc;
    bloc.add(
      RenewCustomerEvent(
        customer: widget.customer,
        amountReceived: _enteredAmount,
        renewalDate: _renewalDate,
        method: _method,
        notes: _notes.trim().isEmpty ? null : _notes.trim(),
      ),
    );

    // The handler reloads the list on success and emits CustomersError on
    // failure, so either terminal state resolves this wait.
    final settled = await bloc.stream.firstWhere(
      (s) => s is CustomersLoaded || s is CustomersError,
    );
    if (!mounted) return;

    final outcome = bloc.lastRenewal;
    navigator.pop();

    if (settled is CustomersError || outcome == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            settled is CustomersError
                ? settled.message
                : 'Renewal did not complete. Please try again.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final until = DateTimeUtils.formatDate(outcome.renewedUntil ?? _newExpiry);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          outcome.isPaidInFull
              ? '${widget.customer.name} renewed through $until.'
              : '${widget.customer.name} renewed through $until — '
                  '${DateTimeUtils.formatCurrency(outcome.outstanding)} '
                  'still outstanding. Settle it from the Payments page.',
        ),
        backgroundColor: outcome.isPaidInFull
            ? AppTheme.successColor
            : Colors.orange.shade800,
        duration: Duration(seconds: outcome.isPaidInFull ? 3 : 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saveIcon = _isSubmitting
        ? const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : const Icon(Icons.autorenew, size: 16);
    final saveLabel = Text(_isSubmitting ? 'Renewing...' : 'Confirm Renewal');
    final title = 'Renew: ${widget.customer.name}';

    if (widget.isMobileDialog) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(title),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(key: _formKey, child: _form()),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: saveIcon,
                label: saveLabel,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 460,
          child: SingleChildScrollView(child: _form()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: saveIcon,
          label: saveLabel,
        ),
      ],
    );
  }

  Widget _form() {
    final bill = widget.customer.monthlyBill;
    final shortfall = (bill - _enteredAmount).clamp(0.0, double.infinity);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _currentPeriodSummary(),
        const Divider(height: 24),

        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Amount Received (PKR)',
            hintText: 'Full month: ${DateTimeUtils.formatCurrency(bill)}',
            prefixText: 'PKR ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: AppInputFormatters.decimal,
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter an amount';
            final val = double.tryParse(v.trim());
            if (val == null) return 'Enter a valid number';
            if (val <= 0) return 'Amount must be greater than zero';
            if (val > bill) {
              return 'Cannot exceed the monthly bill '
                  '(${DateTimeUtils.formatCurrency(bill)})';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _method,
          decoration: const InputDecoration(labelText: 'Payment Method'),
          items: const [
            DropdownMenuItem(value: 'cash', child: Text('Cash')),
            DropdownMenuItem(value: 'bankTransfer', child: Text('Bank Transfer')),
            DropdownMenuItem(value: 'easypaisa', child: Text('EasyPaisa')),
            DropdownMenuItem(value: 'jazzcash', child: Text('JazzCash')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _method = v);
          },
        ),
        const SizedBox(height: 8),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
          title: const Text('Renewal Date', style: TextStyle(fontSize: 13)),
          subtitle: Text(
            DateTimeUtils.formatDate(_renewalDate),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.edit_calendar, size: 18),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _renewalDate,
              firstDate: DateTime(2020),
              lastDate: widget.clock(),
            );
            if (picked != null) {
              setState(() => _renewalDate = BillingCycle.dateOnly(picked));
            }
          },
        ),
        const SizedBox(height: 8),

        TextFormField(
          decoration: const InputDecoration(labelText: 'Notes (Optional)'),
          onChanged: (v) => _notes = v,
        ),
        const SizedBox(height: 16),

        _newExpiryPreview(),
        if (shortfall > 0) ...[
          const SizedBox(height: 10),
          _shortfallNotice(shortfall),
        ],
      ],
    );
  }

  Widget _currentPeriodSummary() {
    final due = widget.customer.effectiveDueDate;
    final now = widget.clock();
    final days = due == null ? null : BillingCycle.daysUntilDue(due, now);

    final String expiryLabel;
    final Color expiryColor;
    if (due == null) {
      expiryLabel = 'No expiry on record';
      expiryColor = AppTheme.mediumGray;
    } else if (days! < 0) {
      expiryLabel =
          '${DateTimeUtils.formatDate(due)} · expired ${-days} day${days == -1 ? '' : 's'} ago';
      expiryColor = AppTheme.errorColor;
    } else if (days == 0) {
      expiryLabel = '${DateTimeUtils.formatDate(due)} · expires today';
      expiryColor = AppTheme.errorColor;
    } else {
      expiryLabel = '${DateTimeUtils.formatDate(due)} · in $days days';
      expiryColor = Colors.orange.shade800;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryRow(Icons.speed, 'Package', widget.packageName),
        _summaryRow(
          Icons.receipt_long,
          'Monthly Bill',
          DateTimeUtils.formatCurrency(widget.customer.monthlyBill),
        ),
        _summaryRow(Icons.event_busy, 'Current Expiry', expiryLabel,
            valueColor: expiryColor),
      ],
    );
  }

  Widget _summaryRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppTheme.mediumGray),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: AppTheme.mediumGray),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppTheme.darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the committed outcome before the operator commits to it — the
  /// renewal date drives the new expiry, so an operator back-dating a
  /// collection can see exactly where the cycle lands.
  Widget _newExpiryPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available,
              size: 18, color: AppTheme.successColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New expiry after renewal',
                  style: TextStyle(fontSize: 11, color: AppTheme.mediumGray),
                ),
                Text(
                  DateTimeUtils.formatDate(_newExpiry),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shortfallNotice(double shortfall) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Part payment. The subscription still renews to '
              '${DateTimeUtils.formatDate(_newExpiry)}, and '
              '${DateTimeUtils.formatCurrency(shortfall)} stays outstanding — '
              'settle it later from the Payments page.',
              style: TextStyle(fontSize: 11.5, color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
