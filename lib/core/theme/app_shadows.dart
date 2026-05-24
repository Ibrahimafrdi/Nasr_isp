import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  // Subtle shadow for subtle elevation
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  // Small shadow for cards and buttons
  static const List<BoxShadow> small = [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // Medium shadow for elevated cards
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // Large shadow for modals and dropdowns
  static const List<BoxShadow> large = [
    BoxShadow(
      color: AppColors.shadowDark,
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  // Hover elevation
  static const List<BoxShadow> hover = [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  // Focus state
  static const List<BoxShadow> focus = [
    BoxShadow(
      color: AppColors.shadowDark,
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];
}
