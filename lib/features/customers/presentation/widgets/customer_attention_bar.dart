import 'package:flutter/material.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/features/customers/presentation/widgets/customer_table.dart';

const Color _kWarnBg = Color(0xFFFFF4E5);
const Color _kWarnBorder = Color(0xFFF2C98A);
const Color _kWarnText = Color(0xFF7A3E00);

/// One bar that combines every renewal alert for the Customers page.
class CustomerAttentionBar extends StatelessWidget {
  final CustomersSummary summary;
  final VoidCallback onShowExpiring;
  final VoidCallback onShowExpired;

  const CustomerAttentionBar({
    super.key,
    required this.summary,
    required this.onShowExpiring,
    required this.onShowExpired,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (summary.expiringSoon > 0) {
      final n = summary.expiringSoon;
      parts.add(
        '$n ${n == 1 ? 'customer expires' : 'customers expire'} '
        'in the next ${BillingCycle.renewalWindowDays} days.',
      );
    }
    if (summary.expired > 0) {
      final n = summary.expired;
      parts.add(
        '$n expired ${n == 1 ? 'customer has' : 'customers have'} '
        'not renewed (${formatRs(summary.expiredAmount)} = their monthly bills).',
      );
    }

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Needs your attention',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kWarnText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          parts.join(' '),
          style: const TextStyle(fontSize: 14, color: _kWarnText),
        ),
      ],
    );

    final buttons = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (summary.expiringSoon > 0)
          OutlinedButton(
            onPressed: onShowExpiring,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kWarnText,
              side: const BorderSide(color: _kWarnBorder),
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Show expiring'),
          ),
        if (summary.expired > 0)
          ElevatedButton(
            onPressed: onShowExpired,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kWarnText,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Show expired'),
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _kWarnBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kWarnBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 12), buttons],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: text),
              const SizedBox(width: 16),
              buttons,
            ],
          );
        },
      ),
    );
  }
}
