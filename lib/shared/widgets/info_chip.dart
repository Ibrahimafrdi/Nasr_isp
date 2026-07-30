import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';

/// A small icon + label chip used in mobile card layouts across multiple
/// features (customers, payments, employees, installations, etc.).
///
/// Pure UI — no BLoC or Firestore access.
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Optional color override for both the icon and label text.
  final Color? color;

  const InfoChip(this.icon, this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color ?? AppTheme.mediumGray),
        const SizedBox(width: 4),
        // Flexible, not a bare Text: a chip inside a Wrap is constrained to
        // the Wrap's width, so a long value (an address, a sector name, a
        // customer's full name) would otherwise overflow the card on a
        // phone rather than truncating.
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: color ?? AppTheme.mediumGray,
              fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
