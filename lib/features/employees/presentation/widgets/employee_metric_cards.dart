import 'package:flutter/material.dart';

/// Team summary cards for the Employees page.
///
/// Pure UI: receives counts and lays itself out as 4 / 2 columns.
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
    final disabled = totalCount - activeCount;
    final avg = activeCount > 0 ? totalSubsAssigned / activeCount : 0.0;
    final avgText = avg == avg.roundToDouble()
        ? avg.round().toString()
        : avg.toStringAsFixed(1);

    final cards = <Widget>[
      _card(
        'Active technicians',
        '$activeCount',
        note: 'Out of $totalCount registered',
        color: const Color(0xFF0F766E),
      ),
      _card(
        'Disabled',
        '$disabled',
        note: 'Cannot take new installations',
        color: disabled > 0 ? const Color(0xFFB42318) : null,
      ),
      _card(
        'Subscribers assigned',
        '$totalSubsAssigned',
        note: 'Installations by active technicians',
      ),
      _card('Average per technician', avgText, note: 'Active technicians only'),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        const gap = 16.0;
        final cols = c.maxWidth >= 900 ? 4 : 2;
        final width = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }
}
