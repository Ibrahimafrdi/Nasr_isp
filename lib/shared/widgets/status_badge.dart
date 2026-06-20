import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/theme/app_typography.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';

enum StatusType { active, expiring, expired, pending, offline, completed }

/// A highly polished, responsive status badge designed for ISP operations.
/// Supports multiple status enums (StatusType, CustomerStatus, PaymentStatus) and raw Strings.
/// Features dynamic color mapping, customizable text styles, responsive constraints,
/// and automatic truncation to avoid UI overflow.
class StatusBadge extends StatelessWidget {
  final dynamic status;
  final String? label;
  final bool showIcon;
  final double? width;
  final TextStyle? textStyle;

  const StatusBadge({
    Key? key,
    required this.status,
    this.label,
    this.showIcon = true,
    this.width,
    this.textStyle,
  }) : super(key: key);

  String get _labelText {
    if (label != null) return label!;
    if (status is String) return status as String;
    if (status is CustomerStatus) return (status as CustomerStatus).label;
    if (status is PaymentStatus) return (status as PaymentStatus).label;
    if (status is StatusType) {
      switch (status as StatusType) {
        case StatusType.active:
          return 'Active';
        case StatusType.expiring:
          return 'Expiring';
        case StatusType.expired:
          return 'Expired';
        case StatusType.pending:
          return 'Pending';
        case StatusType.offline:
          return 'Offline';
        case StatusType.completed:
          return 'Completed';
      }
    }
    return status.toString();
  }

  String _normalizeStatus() {
    if (status is String) {
      return (status as String).toLowerCase().replaceAll(' ', '');
    }
    if (status is CustomerStatus) {
      if (status == CustomerStatus.expiringSoon) return 'expiringsoon';
      return (status as CustomerStatus).name.toLowerCase();
    }
    if (status is PaymentStatus) {
      return (status as PaymentStatus).name.toLowerCase();
    }
    if (status is StatusType) {
      return (status as StatusType).name.toLowerCase();
    }
    return status.toString().toLowerCase().replaceAll(' ', '');
  }

  Color _getColor() {
    final norm = _normalizeStatus();
    switch (norm) {
      case 'active':
      case 'completed':
      case 'success':
        return AppColors.successGreen;
      case 'pending':
      case 'partial':
        return AppColors.warningOrange;
      case 'expiring':
      case 'expiringsoon':
      case 'warning':
        return AppColors.warningOrange;
      case 'expired':
      case 'suspended':
      case 'failed':
      case 'error':
        return AppColors.errorRed;
      case 'offline':
      case 'inactive':
      case 'paused':
      default:
        return AppColors.mediumGray;
    }
  }

  IconData _getIcon() {
    final norm = _normalizeStatus();
    switch (norm) {
      case 'active':
      case 'completed':
      case 'success':
        return Icons.check_circle_outline;
      case 'pending':
      case 'partial':
        return Icons.schedule;
      case 'expiring':
      case 'expiringsoon':
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'expired':
        return Icons.error_outline_rounded;
      case 'suspended':
      case 'failed':
      case 'error':
        return Icons.block_flipped;
      case 'offline':
        return Icons.cloud_off_rounded;
      case 'inactive':
      case 'paused':
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();
    final text = _labelText;

    return Container(
      constraints: BoxConstraints(maxWidth: width ?? 140),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withOpacity(0.24), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              style:
                  textStyle ??
                  AppTypography.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    height: 1.2,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
