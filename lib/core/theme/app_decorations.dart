import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_shadows.dart';

class AppDecorations {
  static BorderRadius get borderRadius => BorderRadius.circular(16);

  static BoxDecoration get enhancedCardDecoration => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.lightGray.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: AppShadows.subtle,
      );

  static BoxDecoration iconContainerDecoration(Color color) => BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      );

  static BoxDecoration trendIndicatorDecoration(bool isPositive) => BoxDecoration(
        color: (isPositive ? AppColors.successGreen : AppColors.errorRed).withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      );
}
