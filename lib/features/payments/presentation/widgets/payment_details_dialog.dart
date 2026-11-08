import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/payments/data/models/payment_model.dart';
import 'package:nasr_isp/shared/widgets/status_badge.dart';

/// Displays a comprehensive, clean receipt slip & metadata modal for a payment.
Future<void> showPaymentDetailsDialog({
  required BuildContext context,
  required PaymentModel payment,
  required bool isAdmin,
  void Function(PaymentModel payment)? onSettle,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: _PaymentDetailsContent(
          payment: payment,
          isAdmin: isAdmin,
          onSettle: onSettle != null
              ? () {
                  Navigator.pop(ctx);
                  onSettle(payment);
                }
              : null,
        ),
      ),
    ),
  );
}

class _PaymentDetailsContent extends StatelessWidget {
  final PaymentModel payment;
  final bool isAdmin;
  final VoidCallback? onSettle;

  const _PaymentDetailsContent({
    required this.payment,
    required this.isAdmin,
    this.onSettle,
  });

  String _methodDisplay(String? method) {
    switch (method) {
      case 'cash':
        return 'Cash Collection';
      case 'bankTransfer':
        return 'Direct Bank Transfer';
      case 'easypaisa':
        return 'EasyPaisa Mobile Wallet';
      case 'jazzcash':
        return 'JazzCash Mobile Wallet';
      default:
        return method?.isNotEmpty == true ? method! : 'Unspecified';
    }
  }

  IconData _methodIcon(String? method) {
    switch (method) {
      case 'cash':
        return Icons.payments_rounded;
      case 'bankTransfer':
        return Icons.account_balance_rounded;
      case 'easypaisa':
      case 'jazzcash':
        return Icons.phone_android_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.status == 'paid';
    final hasBalance = payment.remainingAmount > 0;
    final coversTo = payment.periodEnd ?? payment.dueDate;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Receipt',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                      Text(
                        payment.id.isNotEmpty
                            ? 'ID: ${payment.id.length > 12 ? payment.id.substring(0, 12) : payment.id}'
                            : 'Subscription Charge',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.darkGray,
                ),
                onPressed: () => Navigator.pop(context),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Receipt Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isPaid
                  ? AppColors.successGreen.withValues(alpha: 0.08)
                  : (hasBalance
                        ? AppColors.warningOrange.withValues(alpha: 0.08)
                        : AppColors.errorRed.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPaid
                    ? AppColors.successGreen.withValues(alpha: 0.25)
                    : (hasBalance
                          ? AppColors.warningOrange.withValues(alpha: 0.25)
                          : AppColors.errorRed.withValues(alpha: 0.25)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPaid
                          ? 'Settled in Full'
                          : (hasBalance
                                ? 'Partially Paid'
                                : 'Payment Overdue / Open'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isPaid
                            ? AppColors.successGreen
                            : (hasBalance
                                  ? AppColors.warningOrange
                                  : AppColors.errorRed),
                      ),
                    ),
                  ],
                ),
                StatusBadge(status: payment.status),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Customer Profile Snapshot
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryBlue.withValues(
                    alpha: 0.12,
                  ),
                  child: Text(
                    payment.customerName.isNotEmpty
                        ? payment.customerName[0].toUpperCase()
                        : 'C',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.customerName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                      if (payment.billingMonth != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Billing Cycle: ${payment.billingMonth}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.darkGray,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Ledger Breakdown Table
          Text(
            'Ledger Summary',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ReceiptRow(
            label: 'Total Invoiced (Billed)',
            value: DateTimeUtils.formatCurrency(payment.amount),
            isBold: true,
          ),
          _ReceiptRow(
            label: 'Amount Collected (Paid)',
            value: DateTimeUtils.formatCurrency(payment.paidAmount),
            valueColor: AppColors.successGreen,
            isBold: true,
          ),
          const Divider(height: 16, color: AppColors.lightGray),
          _ReceiptRow(
            label: 'Outstanding Balance Due',
            value: DateTimeUtils.formatCurrency(payment.remainingAmount),
            valueColor: payment.remainingAmount > 0
                ? AppColors.errorRed
                : AppColors.successGreen,
            isBold: true,
          ),
          const SizedBox(height: AppSpacing.md),

          // Metadata Details
          Text(
            'Transaction Details',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ReceiptRow(
            label: 'Collection Method',
            value: _methodDisplay(payment.method),
            leadingIcon: _methodIcon(payment.method),
          ),
          if (coversTo != null)
            _ReceiptRow(
              label: 'Subscription Validity',
              value: 'Until ${DateTimeUtils.formatDate(coversTo)}',
              leadingIcon: Icons.calendar_today_rounded,
            ),
          if (payment.createdAt != null)
            _ReceiptRow(
              label: 'Invoiced Date',
              value: DateTimeUtils.formatDate(payment.createdAt!),
              leadingIcon: Icons.schedule_rounded,
            ),
          if (payment.completedDate != null)
            _ReceiptRow(
              label: 'Settlement Completed',
              value: DateTimeUtils.formatDate(payment.completedDate!),
              leadingIcon: Icons.task_alt_rounded,
            ),
          if (payment.notes?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes / Reference:',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payment.notes!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),

          // Action Button Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final buffer = StringBuffer();
                    buffer.writeln('---ISP NASR PAYMENT RECEIPT ---');
                    buffer.writeln('Customer: ${payment.customerName}');
                    buffer.writeln('Cycle: ${payment.billingMonth ?? "N/A"}');
                    buffer.writeln(
                      'Billed: ${DateTimeUtils.formatCurrency(payment.amount)}',
                    );
                    buffer.writeln(
                      'Collected: ${DateTimeUtils.formatCurrency(payment.paidAmount)}',
                    );
                    buffer.writeln(
                      'Balance Due: ${DateTimeUtils.formatCurrency(payment.remainingAmount)}',
                    );
                    buffer.writeln('Method: ${_methodDisplay(payment.method)}');
                    buffer.writeln('Status: ${payment.status.toUpperCase()}');
                    _copyToClipboard(
                      context,
                      buffer.toString(),
                      'Receipt details',
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy Receipt'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.charcoal,
                    side: const BorderSide(color: AppColors.lightGray),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (isAdmin && !isPaid && onSettle != null) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSettle,
                    icon: const Icon(Icons.payments_rounded, size: 16),
                    label: const Text('Settle Balance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;
  final IconData? leadingIcon;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 14, color: AppColors.darkGray),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isBold ? AppColors.charcoal : AppColors.darkGray,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? AppColors.navyDark,
            ),
          ),
        ],
      ),
    );
  }
}
