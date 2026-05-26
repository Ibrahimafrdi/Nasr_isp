import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_fonts.dart';
import 'package:nasr_isp/core/theme/app_decorations.dart';

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? change;
  final bool? isPositive;

  const DashboardStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.change,
    this.isPositive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: AppDecorations.enhancedCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: AppDecorations.iconContainerDecoration(color),
                  child: Icon(
                    icon, 
                    color: color, 
                    size: 16,
                  ),
                ),
                if (change != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4, 
                      vertical: 2,
                    ),
                    decoration: AppDecorations.trendIndicatorDecoration(isPositive ?? true),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (isPositive ?? true) 
                              ? Icons.trending_up 
                              : Icons.trending_down,
                          size: 10,
                          color: (isPositive ?? true) 
                              ? AppColors.success 
                              : AppColors.error,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          change!,
                          style: AppFonts.labelSmall.copyWith(
                            color: (isPositive ?? true) 
                                ? AppColors.success 
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppFonts.displaySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppFonts.bodySmallMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
