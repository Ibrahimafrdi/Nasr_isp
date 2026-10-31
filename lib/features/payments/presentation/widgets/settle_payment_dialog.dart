import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/utils/input_formatters.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/payments/data/models/payment_model.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';

/// Shows the high-polish Settle Payment modal dialog on desktop
/// or full-screen bottom sheet on mobile.
Future<void> showSettlePaymentDialog({
  required BuildContext context,
  required PaymentModel payment,
  required Future<void> Function({
    required double receivedAmount,
    required String method,
    required String? notes,
  }) onConfirm,
}) {
  final isMobile = Responsive.isMobile(context);

  if (isMobile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SettlePaymentSheet(
        payment: payment,
        onConfirm: onConfirm,
      ),
    );
  }

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _SettlePaymentDialogContent(
          payment: payment,
          onConfirm: onConfirm,
        ),
      ),
    ),
  );
}

class _SettlePaymentDialogContent extends StatefulWidget {
  final PaymentModel payment;
  final Future<void> Function({
    required double receivedAmount,
    required String method,
    required String? notes,
  }) onConfirm;

  const _SettlePaymentDialogContent({
    required this.payment,
    required this.onConfirm,
  });

  @override
  State<_SettlePaymentDialogContent> createState() =>
      _SettlePaymentDialogContentState();
}

class _SettlePaymentDialogContentState
    extends State<_SettlePaymentDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late String _selectedMethod;
  bool _isSubmitting = false;
  double _enteredAmount = 0.0;

  @override
  void initState() {
    super.initState();
    final remaining = widget.payment.remainingAmount;
    _amountController = TextEditingController(
      text: remaining.toStringAsFixed(0),
    );
    _enteredAmount = remaining;
    _notesController = TextEditingController(text: widget.payment.notes ?? '');
    _selectedMethod = widget.payment.method?.isNotEmpty == true
        ? widget.payment.method!
        : 'cash';

    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    final val = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (val != _enteredAmount) {
      setState(() => _enteredAmount = val);
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setPreset(double amount) {
    final clamped = amount.clamp(0.0, widget.payment.remainingAmount);
    _amountController.text = clamped.toStringAsFixed(0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text.trim());
      final notes = _notesController.text.trim();
      await widget.onConfirm(
        receivedAmount: amount,
        method: _selectedMethod,
        notes: notes.isNotEmpty ? notes : null,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final remaining = payment.remainingAmount;
    final newRemaining = (remaining - _enteredAmount).clamp(0.0, double.infinity);
    final isSettlingInFull = _enteredAmount >= remaining;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settle Invoice Balance',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        payment.customerName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.darkGray,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.darkGray),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Financial Breakdown Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF8FAFC),
                    AppColors.skyBlue.withValues(alpha: 0.25),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BalanceMetric(
                        label: 'Total Invoiced',
                        value: DateTimeUtils.formatCurrency(payment.amount),
                        color: AppColors.charcoal,
                      ),
                      Container(width: 1, height: 32, color: AppColors.lightGray),
                      _BalanceMetric(
                        label: 'Already Paid',
                        value: DateTimeUtils.formatCurrency(payment.paidAmount),
                        color: AppColors.successGreen,
                      ),
                      Container(width: 1, height: 32, color: AppColors.lightGray),
                      _BalanceMetric(
                        label: 'Balance Due',
                        value: DateTimeUtils.formatCurrency(remaining),
                        color: AppColors.errorRed,
                        isHighlighted: true,
                      ),
                    ],
                  ),
                  if (payment.billingMonth != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1, color: AppColors.lightGray),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Billing Cycle: ${payment.billingMonth}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.darkGray,
                          ),
                        ),
                        Text(
                          'Arrears settlement only',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quick Amount Presets
            Row(
              children: [
                Text(
                  'Quick Fill:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  children: [
                    _PresetButton(
                      label: 'Full Balance',
                      onTap: () => _setPreset(remaining),
                      isSelected: _enteredAmount == remaining,
                    ),
                    if (remaining > 500) ...[
                      _PresetButton(
                        label: '50%',
                        onTap: () => _setPreset(remaining * 0.5),
                        isSelected: _enteredAmount == (remaining * 0.5),
                      ),
                    ],
                    _PresetButton(
                      label: 'Clear',
                      onTap: () => _setPreset(0),
                      isSelected: _enteredAmount == 0,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Amount Input Field
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: AppInputFormatters.decimal,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
              decoration: InputDecoration(
                labelText: 'Payment Amount Collected',
                labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Text(
                    'PKR',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.lightGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.lightGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter collection amount';
                }
                final numVal = double.tryParse(v.trim());
                if (numVal == null || numVal <= 0) {
                  return 'Enter a valid positive number';
                }
                if (numVal > remaining) {
                  return 'Amount cannot exceed balance of ${DateTimeUtils.formatCurrency(remaining)}';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xs),

            // Dynamic Balance Feedback
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    isSettlingInFull
                        ? Icons.check_circle_outline_rounded
                        : Icons.info_outline_rounded,
                    size: 14,
                    color: isSettlingInFull
                        ? AppColors.successGreen
                        : AppColors.warningOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSettlingInFull
                        ? 'Charge will be fully settled (Balance: Rs 0)'
                        : 'New remaining balance: ${DateTimeUtils.formatCurrency(newRemaining)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSettlingInFull
                          ? AppColors.successGreen
                          : AppColors.warningOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Payment Method Selector
            Text(
              'Collection Method',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _MethodCard(
                    title: 'Cash',
                    icon: Icons.payments_rounded,
                    isSelected: _selectedMethod == 'cash',
                    onTap: () => setState(() => _selectedMethod = 'cash'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MethodCard(
                    title: 'Bank',
                    icon: Icons.account_balance_rounded,
                    isSelected: _selectedMethod == 'bankTransfer',
                    onTap: () => setState(() => _selectedMethod = 'bankTransfer'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MethodCard(
                    title: 'EasyPaisa',
                    icon: Icons.phone_android_rounded,
                    isSelected: _selectedMethod == 'easypaisa',
                    onTap: () => setState(() => _selectedMethod = 'easypaisa'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MethodCard(
                    title: 'JazzCash',
                    icon: Icons.mobile_friendly_rounded,
                    isSelected: _selectedMethod == 'jazzcash',
                    onTap: () => setState(() => _selectedMethod = 'jazzcash'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Notes / Ref
            TextFormField(
              controller: _notesController,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.navyDark),
              decoration: InputDecoration(
                labelText: 'Reference / Notes (Optional)',
                hintText: 'e.g. Bank slip, transaction ID, collector note',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.mediumGray),
                prefixIcon: const Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                  color: AppColors.darkGray,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.lightGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.lightGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.charcoal,
                      side: const BorderSide(color: AppColors.lightGray),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSettlingInFull
                          ? AppColors.successGreen
                          : AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(
                      _isSubmitting
                          ? 'Recording Receipt...'
                          : 'Record Receipt (${DateTimeUtils.formatCurrency(_enteredAmount)})',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettlePaymentSheet extends StatelessWidget {
  final PaymentModel payment;
  final Future<void> Function({
    required double receivedAmount,
    required String method,
    required String? notes,
  }) onConfirm;

  const _SettlePaymentSheet({
    required this.payment,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: _SettlePaymentDialogContent(
                payment: payment,
                onConfirm: onConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isHighlighted;

  const _BalanceMetric({
    required this.label,
    required this.value,
    required this.color,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.darkGray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isHighlighted ? 15 : 13,
              fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _PresetButton({
    required this.label,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.12)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.lightGray,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryBlue : AppColors.charcoal,
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.lightGray,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primaryBlue : AppColors.darkGray,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryBlue : AppColors.charcoal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

