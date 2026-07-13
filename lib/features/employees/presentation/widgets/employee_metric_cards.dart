import 'package:flutter/material.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

/// Responsive team KPI card row for the Employees page.
///
/// Pure UI — receives count values and adapts to mobile/desktop screens.
class EmployeeMetricCards extends StatelessWidget {
  final int totalCount;
  final int activeCount;
  final int totalSubsAssigned;
  final bool isMobile;

  const EmployeeMetricCards({
    super.key,
    required this.totalCount,
    required this.activeCount,
    required this.totalSubsAssigned,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final double avgSubs = activeCount > 0 ? (totalSubsAssigned / activeCount) : 0.0;

    final cards = [
      DashboardCard(
        label: 'Total Field Personnel',
        value: activeCount.toString(),
        icon: Icons.groups_outlined,
        subtitle: 'Out of $totalCount total registered',
      ),
      DashboardCard(
        label: 'Subscribers Assigned',
        value: totalSubsAssigned.toString(),
        icon: Icons.supervised_user_circle_outlined,
        subtitle: '${avgSubs.toStringAsFixed(0)} avg/tech (active only)',
      ),
      DashboardCard(
        label: 'Avg Billing Efficiency',
        value: '—',
        icon: Icons.assignment_turned_in_outlined,
        backgroundColor: Colors.white,
        subtitle: 'Attribution feature coming soon',
        // TODO: Wire to real collection-efficiency data once payment-to-employee
        // attribution exists. Currently no field links a Payment to the employee
        // who collected it. Do not fabricate this number from unrelated data.
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          cards[2],
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
  }
}
