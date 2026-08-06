import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/payments/data/models/payment_model.dart';
import 'package:nasr_isp/shared/widgets/info_chip.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

/// Mobile card list for the Payments page.
///
/// Pure UI — callbacks are provided by the parent page.
class PaymentCardList extends StatelessWidget {
  final List<PaymentModel> payments;
  final bool isAdmin;

  /// Called when the user taps "Settle" on a card with a balance still owed.
  final void Function(PaymentModel payment) onRecordPayment;

  const PaymentCardList({
    super.key,
    required this.payments,
    required this.isAdmin,
    required this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: payments.map((payment) => _PaymentCard(
        payment: payment,
        isAdmin: isAdmin,
        onRecordPayment: onRecordPayment,
      )).toList(),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final bool isAdmin;
  final void Function(PaymentModel payment) onRecordPayment;

  const _PaymentCard({
    required this.payment,
    required this.isAdmin,
    required this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.status == 'paid';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightGray.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer name + status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  payment.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              PaymentStatusBadge(status: payment.status),
            ],
          ),
          const SizedBox(height: 10),

          // Info chips
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              if (isAdmin) ...[
                InfoChip(
                  Icons.monetization_on,
                  DateTimeUtils.formatCurrency(payment.amount),
                ),
                InfoChip(
                  Icons.check_circle,
                  'Paid: ${DateTimeUtils.formatCurrency(payment.paidAmount)}',
                ),
                InfoChip(
                  Icons.warning_amber,
                  'Due: ${DateTimeUtils.formatCurrency(payment.remainingAmount)}',
                  color: payment.remainingAmount > 0
                      ? AppTheme.errorColor
                      : AppTheme.successColor,
                ),
              ],
              if (payment.billingMonth != null)
                InfoChip(Icons.calendar_today, payment.billingMonth!),
              if (payment.periodEnd != null)
                InfoChip(
                  Icons.event_available,
                  'Covers to ${DateTimeUtils.formatDate(payment.periodEnd!)}',
                ),
              InfoChip(Icons.credit_card, payment.method ?? 'N/A'),
            ],
          ),

          if (isAdmin && !isPaid) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.price_check, size: 16),
                label: const Text('Settle', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.primaryColor,
                ),
                onPressed: () => onRecordPayment(payment),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
