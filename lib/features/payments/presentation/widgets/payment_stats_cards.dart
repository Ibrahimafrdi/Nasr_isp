import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

/// Three-card stats row shown at the top of the Payments page (admin-only).
///
/// Pure UI — receives values from [PaymentsPage] via BLoC state.
class PaymentStatsCards extends StatelessWidget {
  final double totalAmount;
  final double collectedAmount;

  const PaymentStatsCards({
    super.key,
    required this.totalAmount,
    required this.collectedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      DashboardCard(
        label: 'Current Billing Target',
        value: DateTimeUtils.formatCurrency(totalAmount),
        icon: Icons.monetization_on,
      ),
      DashboardCard(
        label: 'Collections Realized',
        value: DateTimeUtils.formatCurrency(collectedAmount),
        icon: Icons.check_circle_outline,
        backgroundColor: AppTheme.successColor.withValues(alpha: 0.05),
      ),
      DashboardCard(
        label: 'Total Outstanding Dues',
        value: DateTimeUtils.formatCurrency(totalAmount - collectedAmount),
        icon: Icons.pending_actions,
        backgroundColor: AppTheme.errorColor.withValues(alpha: 0.05),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: cards[1]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[2]),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
            const SizedBox(width: 16),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }
}
