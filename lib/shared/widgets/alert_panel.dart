import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/theme/app_typography.dart';
import 'package:nasr_isp/core/theme/app_shadows.dart';

enum AlertType { info, warning, error, success }

class AlertPanel extends StatelessWidget {
  final AlertType type;
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onActionTap;
  final String? actionLabel;
  final bool dismissible;
  final VoidCallback? onDismiss;

  const AlertPanel({
    Key? key,
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    this.onActionTap,
    this.actionLabel,
    this.dismissible = true,
    this.onDismiss,
  }) : super(key: key);

  Color _getBackgroundColor() {
    switch (type) {
      case AlertType.info:
        return AppColors.skyBlue;
      case AlertType.warning:
        return Color(0xFFFEF3C7);
      case AlertType.error:
        return Color(0xFFFEE2E2);
      case AlertType.success:
        return Color(0xFFDCFCE7);
    }
  }

  Color _getTextColor() {
    switch (type) {
      case AlertType.info:
        return AppColors.infoBlue;
      case AlertType.warning:
        return Color(0xFF92400E);
      case AlertType.error:
        return Color(0xFF7F1D1D);
      case AlertType.success:
        return Color(0xFF166534);
    }
  }

  Color _getIconBackgroundColor() {
    switch (type) {
      case AlertType.info:
        return AppColors.infoBlue.withOpacity(0.15);
      case AlertType.warning:
        return AppColors.warningOrange.withOpacity(0.15);
      case AlertType.error:
        return AppColors.errorRed.withOpacity(0.15);
      case AlertType.success:
        return AppColors.successGreen.withOpacity(0.15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: _getTextColor().withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: _getTextColor().withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: _getIconBackgroundColor(),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(icon, color: _getTextColor(), size: 24),
          ),
          SizedBox(width: AppSpacing.lg),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headingSmall.copyWith(
                    color: _getTextColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: _getTextColor().withOpacity(0.85),
                  ),
                ),
                if (onActionTap != null && actionLabel != null) ...[
                  SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: onActionTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getTextColor(),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      actionLabel!,
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (dismissible) ...[
            SizedBox(width: AppSpacing.lg),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: _getTextColor().withOpacity(0.6),
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
