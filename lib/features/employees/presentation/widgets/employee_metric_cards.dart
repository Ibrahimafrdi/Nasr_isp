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
    ];

    return Row(
      children: [
        Expanded(child: cards[0]),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(child: cards[1]),
      ],
    );
  }
}
