import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/theme/app_typography.dart';

class ActivityTimelineItem {
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData icon;
  final Color? color;
  final String? badge;

  ActivityTimelineItem({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    this.color,
    this.badge,
  });
}

/// ActivityTimelineWidget - Recent activity timeline display
/// 
/// Features:
/// - Clean timeline layout
/// - Activity items with icons
/// - Time display (relative or absolute)
/// - Color-coded activities
/// - Professional styling
class ActivityTimelineWidget extends StatelessWidget {
  final List<ActivityTimelineItem> items;
  final String title;
  final VoidCallback? onViewMore;

  const ActivityTimelineWidget({
    Key? key,
    required this.items,
    this.title = 'Recent Activity',
    this.onViewMore,
  }) : super(key: key);

  String _getTimeString(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.lightGray.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTypography.headingMedium.copyWith(
                    color: AppColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (onViewMore != null)
                  TextButton(
                    onPressed: onViewMore,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                    ),
                    child: Text(
                      'View all',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Divider(
            color: AppColors.lightGray.withOpacity(0.5),
            height: 1,
            thickness: 1,
          ),

          // Timeline Items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;
            final color = item.color ?? AppColors.primaryBlue;

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline dot and line
                      Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                item.icon,
                                size: 20,
                                color: color,
                              ),
                            ),
                          ),
                          if (!isLast) ...[
                            SizedBox(height: AppSpacing.xs),
                            Container(
                              width: 2,
                              height: 40,
                              color: AppColors.lightGray.withOpacity(0.5),
                            ),
                          ],
                        ],
                      ),

                      // Content
                      SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (item.badge != null) ...[
                                  SizedBox(width: AppSpacing.md),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.badge!,
                                      style: AppTypography.captionSmall
                                          .copyWith(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              item.description,
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.darkGray,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              _getTimeString(item.timestamp),
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.mediumGray,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    color: AppColors.lightGray.withOpacity(0.3),
                    height: 1,
                    thickness: 1,
                    indent: AppSpacing.lg + 20,
                    endIndent: AppSpacing.lg,
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
