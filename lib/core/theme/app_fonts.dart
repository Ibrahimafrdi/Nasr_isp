import 'package:flutter/material.dart';
import 'app_typography.dart';
import 'app_colors.dart';

class AppFonts {
  static TextStyle get displayLarge => AppTypography.displayLarge;
  static TextStyle get displayMedium => AppTypography.displayMedium;
  static TextStyle get displaySmall => AppTypography.displaySmall;
  static TextStyle get headlineLarge => AppTypography.headingXLarge;
  static TextStyle get headlineMedium => AppTypography.headingLarge;
  static TextStyle get headlineSmall => AppTypography.headingMedium;
  static TextStyle get bodyLarge => AppTypography.bodyLarge;
  static TextStyle get bodyMedium => AppTypography.bodyMedium;
  static TextStyle get bodySmall => AppTypography.bodySmall;
  static TextStyle get labelLarge => AppTypography.labelLarge;
  static TextStyle get labelMedium => AppTypography.labelMedium;
  static TextStyle get labelSmall => AppTypography.labelSmall;

  static TextStyle get bodyMediumMuted => AppTypography.bodyMedium.copyWith(color: AppColors.mediumGray);
  static TextStyle get bodySmallMuted => AppTypography.bodySmall.copyWith(color: AppColors.mediumGray);

  static const FontWeight normal = FontWeight.normal;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.bold;
  static const FontWeight extraBold = FontWeight.w800;
}
