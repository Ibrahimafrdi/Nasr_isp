import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/theme/app_typography.dart';

enum StatusChipType {
  active,
  pending,
  expiringSoon,
  expired,
  suspended,
  completed,
  offline,
  paused,
}

/// Enhanced StatusChipWidget - Professional status display with proper sizing
/// 
/// Features:
/// - Auto-adjusting height based on content
/// - Proper icon spacing and sizing
/// - No text clipping
/// - Consistent border radius
/// - Professional color palette
/// - Responsive sizing
class StatusChipWidget extends StatelessWidget {
  final StatusChipType type;
  final String label;
  final bool showIcon;
  final double? width;
  final TextStyle? textStyle;

  const StatusChipWidget({
    Key? key,
    required this.type,
    required this.label,
    this.showIcon = true,
    this.width,
    this.textStyle,
  }) : super(key: key);

  Color _getBackgroundColor() {
    switch (type) {
      case StatusChipType.active:
        return AppColors.successGreen.withOpacity(0.12);
      case StatusChipType.pending:
        return AppColors.pendingYellow.withOpacity(0.12);
      case StatusChipType.expiringSoon:
        return AppColors.warningOrange.withOpacity(0.12);
      case StatusChipType.expired:
        return AppColors.errorRed.withOpacity(0.12);
      case StatusChipType.suspended:
        return AppColors.errorRed.withOpacity(0.12);
      case StatusChipType.completed:
        return AppColors.successGreen.withOpacity(0.12);
      case StatusChipType.offline:
        return AppColors.mediumGray.withOpacity(0.12);
      case StatusChipType.paused:
        return AppColors.mediumGray.withOpacity(0.12);
    }
  }

  Color _getTextColor() {
    switch (type) {
      case StatusChipType.active:
        return AppColors.successGreen;
      case StatusChipType.pending:
        return Color(0xFFF59E0B);
      case StatusChipType.expiringSoon:
        return AppColors.warningOrange;
      case StatusChipType.expired:
        return AppColors.errorRed;
      case StatusChipType.suspended:
        return AppColors.errorRed;
      case StatusChipType.completed:
        return AppColors.successGreen;
      case StatusChipType.offline:
        return AppColors.mediumGray;
      case StatusChipType.paused:
        return AppColors.mediumGray;
    }
  }

  Color _getBorderColor() {
    return _getTextColor().withOpacity(0.25);
  }

  IconData _getIcon() {
    switch (type) {
      case StatusChipType.active:
        return Icons.check_circle;
      case StatusChipType.pending:
        return Icons.schedule;
      case StatusChipType.expiringSoon:
        return Icons.warning;
      case StatusChipType.expired:
        return Icons.error;
      case StatusChipType.suspended:
        return Icons.block;
      case StatusChipType.completed:
        return Icons.done_all;
      case StatusChipType.offline:
        return Icons.cloud_off;
      case StatusChipType.paused:
        return Icons.pause_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = this.textStyle ??
        AppTypography.labelSmall.copyWith(
          color: _getTextColor(),
          fontWeight: FontWeight.w600,
          fontSize: 13,
          height: 1.4,
        );

    return Container(
      constraints: BoxConstraints(maxWidth: width ?? 200),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6, // Increased from sm (8) to 6 for better visual balance
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getIcon(),
              size: 16,
              color: _getTextColor(),
            ),
            SizedBox(width: AppSpacing.xs + 2), // 6px spacing
          ],
          Flexible(
            child: Text(
              label,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
