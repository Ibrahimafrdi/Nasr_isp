import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/theme/app_typography.dart';
import 'package:nasr_isp/core/theme/app_shadows.dart';

enum StatusType { active, expiring, expired, pending, offline }

class StatusBadge extends StatelessWidget {
  final StatusType status;
  final String label;
  final bool showIcon;

  const StatusBadge({
    Key? key,
    required this.status,
    required this.label,
    this.showIcon = true,
  }) : super(key: key);

  Color _getBackgroundColor() {
    switch (status) {
      case StatusType.active:
        return AppColors.successGreen.withOpacity(0.1);
      case StatusType.expiring:
        return AppColors.warningOrange.withOpacity(0.1);
      case StatusType.expired:
        return AppColors.errorRed.withOpacity(0.1);
      case StatusType.pending:
        return AppColors.pendingYellow.withOpacity(0.1);
      case StatusType.offline:
        return AppColors.mediumGray.withOpacity(0.1);
    }
  }

  Color _getTextColor() {
    switch (status) {
      case StatusType.active:
        return AppColors.successGreen;
      case StatusType.expiring:
        return AppColors.warningOrange;
      case StatusType.expired:
        return AppColors.errorRed;
      case StatusType.pending:
        return Color(0xFFF59E0B);
      case StatusType.offline:
        return AppColors.mediumGray;
    }
  }

  IconData _getIcon() {
    switch (status) {
      case StatusType.active:
        return Icons.check_circle;
      case StatusType.expiring:
        return Icons.warning;
      case StatusType.expired:
        return Icons.error;
      case StatusType.pending:
        return Icons.schedule;
      case StatusType.offline:
        return Icons.cloud_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: _getTextColor().withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(_getIcon(), size: 14, color: _getTextColor()),
            SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: _getTextColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
