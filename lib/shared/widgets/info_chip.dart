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
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color ?? AppTheme.mediumGray,
            fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
