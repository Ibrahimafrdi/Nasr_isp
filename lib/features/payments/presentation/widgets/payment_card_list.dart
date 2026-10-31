import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/payments/data/models/payment_model.dart';
import 'package:nasr_isp/shared/widgets/status_badge.dart';

/// Enterprise Mobile Card List for Payments.
/// Designed for high information density, touch ergonomics,
/// and guaranteed zero-overflow layout at all viewport widths (320dp+).
class PaymentCardList extends StatelessWidget {
  final List<PaymentModel> payments;
  final bool isAdmin;
  final void Function(PaymentModel payment) onRecordPayment;
  final void Function(PaymentModel payment)? onViewReceipt;

  const PaymentCardList({
    super.key,
    required this.payments,
    required this.isAdmin,
    required this.onRecordPayment,
    this.onViewReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: payments
          .map(
            (payment) => _PaymentMobileCard(
              payment: payment,
              isAdmin: isAdmin,
              onRecordPayment: onRecordPayment,
              onViewReceipt: onViewReceipt,
            ),
          )
          .toList(),
    );
  }
}

class _PaymentMobileCard extends StatelessWidget {
  final PaymentModel payment;
  final bool isAdmin;
  final void Function(PaymentModel payment) onRecordPayment;
  final void Function(PaymentModel payment)? onViewReceipt;

  const _PaymentMobileCard({
    required this.payment,
    required this.isAdmin,
    required this.onRecordPayment,
    this.onViewReceipt,
  });

  String _methodLabel(String? method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'bankTransfer':
        return 'Bank Transfer';
      case 'easypaisa':
        return 'EasyPaisa';
      case 'jazzcash':
        return 'JazzCash';
      default:
        return method?.isNotEmpty == true ? method! : 'N/A';
    }
  }

  IconData _methodIcon(String? method) {
    switch (method) {
      case 'cash':
        return Icons.payments_outlined;
      case 'bankTransfer':
        return Icons.account_balance_outlined;
      case 'easypaisa':
      case 'jazzcash':
        return Icons.phone_android_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.status == 'paid';
    final hasBalance = payment.remainingAmount > 0;
    final coversTo = payment.periodEnd ?? payment.dueDate;
    final double percent = payment.amount > 0
        ? (payment.paidAmount / payment.amount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onViewReceipt != null ? () => onViewReceipt!(payment) : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row: Avatar + Customer Name + Status Badge
                Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor:
                          AppColors.primaryBlue.withValues(alpha: 0.1),
                      child: Text(
                        payment.customerName.isNotEmpty
                            ? payment.customerName[0].toUpperCase()
                            : 'C',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.customerName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (payment.billingMonth != null)
                            Text(
                              'Cycle ${payment.billingMonth}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.darkGray,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    StatusBadge(status: payment.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Financial Summary Grid
                if (isAdmin) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _AmountBlock(
                              label: 'Billed',
                              value: DateTimeUtils.formatCurrency(payment.amount),
                              color: AppColors.charcoal,
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: AppColors.lightGray,
                            ),
                            _AmountBlock(
                              label: 'Collected',
                              value: DateTimeUtils.formatCurrency(payment.paidAmount),
                              color: AppColors.successGreen,
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: AppColors.lightGray,
                            ),
                            _AmountBlock(
                              label: 'Balance',
                              value: DateTimeUtils.formatCurrency(payment.remainingAmount),
                              color: hasBalance
                                  ? AppColors.errorRed
                                  : AppColors.successGreen,
                              isBold: hasBalance,
                            ),
                          ],
                        ),
                        if (!isPaid && payment.paidAmount > 0) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 5,
                              backgroundColor: AppColors.lightGray,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.successGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Metadata Chips Row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _InfoTag(
                      icon: _methodIcon(payment.method),
                      label: _methodLabel(payment.method),
                    ),
                    if (coversTo != null)
                      _InfoTag(
                        icon: Icons.event_available_rounded,
                        label: 'Until ${DateTimeUtils.formatDate(coversTo)}',
                      ),
                  ],
                ),

                // Settle Button
                if (isAdmin && !isPaid) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => onRecordPayment(payment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.payments_rounded, size: 16),
                      label: Text(
                        'Settle Balance (${DateTimeUtils.formatCurrency(payment.remainingAmount)})',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _AmountBlock({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
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
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.darkGray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
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

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.darkGray),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.charcoal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
