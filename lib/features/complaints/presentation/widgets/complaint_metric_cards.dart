import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/complaints/domain/entities/complaint_entity.dart';

class ComplaintMetricCards extends StatelessWidget {
  final List<ComplaintEntity> complaints;
  final bool isMobile;

  const ComplaintMetricCards({
    super.key,
    required this.complaints,
    required this.isMobile,
  });

  static const _ink = Color(0xFF14213D);
  static const _muted = Color(0xFF5B6472);
  static const _border = Color(0xFFE3E6EB);

  Widget _card(String label, String value, {String? note, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color ?? _ink,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note, style: const TextStyle(fontSize: 12, color: _muted)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final openCount =
        complaints.where((c) => c.status == ComplaintStatus.open).length;

    final inProgressCount =
        complaints.where((c) => c.status == ComplaintStatus.inProgress).length;

    final resolvedThisMonthCount = complaints.where((c) {
      final isResolved = c.status == ComplaintStatus.resolved ||
          c.status == ComplaintStatus.closed;
      if (!isResolved) return false;
      final date = c.resolvedAt ?? c.updatedAt;
      return date.year == now.year && date.month == now.month;
    }).length;

    final urgentOpenCount = complaints.where((c) {
      final isOpen = c.status == ComplaintStatus.open ||
          c.status == ComplaintStatus.inProgress;
      return isOpen && c.priority == ComplaintPriority.urgent;
    }).length;

    final cards = [
      _card(
        'Open',
        openCount.toString(),
        note: 'Awaiting action',
        color: const Color(0xFF2563EB),
      ),
      _card(
        'In Progress',
        inProgressCount.toString(),
        note: 'Being investigated',
        color: const Color(0xFFD97706),
      ),
      _card(
        'Resolved this month',
        resolvedThisMonthCount.toString(),
        note: 'Closed & resolved',
        color: const Color(0xFF10B981),
      ),
      _card(
        'Urgent open',
        urgentOpenCount.toString(),
        note: 'Requires immediate attention',
        color: const Color(0xFFDC2626),
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
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
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
        const SizedBox(width: 16),
        Expanded(child: cards[3]),
      ],
    );
  }
}

