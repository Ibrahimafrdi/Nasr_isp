import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

class AppTheme {
  // Backward compatibility color constants - DO NOT use these in new code
  // Use AppColors instead for new components
  static const primaryColor = AppColors.primaryBlue;
  static const primaryDark = AppColors.navyDark;
  static const accentColor = AppColors.successGreen;
  static const successColor = AppColors.successGreen;
  static const warningColor = AppColors.warningOrange;
  static const errorColor = AppColors.errorRed;
  static const infoColor = AppColors.infoBlue;
  static const veryLightGray = AppColors.offWhite;
  static const lightGray = AppColors.lightGray;
  static const mediumGray = AppColors.mediumGray;
  static const darkGray = AppColors.charcoal;
  static const whiteColor = AppColors.white;
  static const surfaceColor = AppColors.white;
  static const surfaceVariant = AppColors.offWhite;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        onPrimary: AppColors.white,
        secondary: AppColors.blueAccent,
        onSecondary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.black,
        error: AppColors.errorRed,
        onError: AppColors.white,
        outline: AppColors.lightGray,
        outlineVariant: AppColors.mediumGray,
      ),
      scaffoldBackgroundColor: AppColors.offWhite,

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 1,
        scrolledUnderElevation: 4,
        centerTitle: false,
        titleTextStyle: AppTypography.headingLarge.copyWith(
          color: AppColors.black,
        ),
        shape: Border(bottom: BorderSide(color: AppColors.lightGray, width: 1)),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: AppColors.lightGray, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.offWhite,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.errorRed, width: 2),
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.mediumGray,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.mediumGray,
        ),
        errorStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.errorRed,
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.black,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.black,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.black,
        ),
        headlineLarge: AppTypography.headingXLarge.copyWith(
          color: AppColors.black,
        ),
        headlineMedium: AppTypography.headingLarge.copyWith(
          color: AppColors.black,
        ),
        headlineSmall: AppTypography.headingMedium.copyWith(
          color: AppColors.black,
        ),
        titleLarge: AppTypography.headingSmall.copyWith(color: AppColors.black),
        titleMedium: AppTypography.bodyLarge.copyWith(
          color: AppColors.charcoal,
        ),
        titleSmall: AppTypography.labelLarge.copyWith(
          color: AppColors.charcoal,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.charcoal),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.charcoal,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.darkGray),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.black),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.charcoal,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.mediumGray,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.labelLarge.copyWith(color: AppColors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          side: BorderSide(color: AppColors.primaryBlue, width: 1.5),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.primaryBlue,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: AppColors.lightGray,
        thickness: 1,
        space: 1,
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryBlue;
          }
          return AppColors.lightGray;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.offWhite,
        labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.charcoal),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: AppColors.lightGray),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryBlue,
        onPrimary: AppColors.navyDark,
        secondary: AppColors.blueAccent,
        onSecondary: AppColors.navyDark,
        surface: AppColors.navyMedium,
        onSurface: AppColors.white,
        error: AppColors.errorRed,
        onError: AppColors.navyDark,
        outline: AppColors.navyLight,
        outlineVariant: AppColors.mediumGray,
      ),
      scaffoldBackgroundColor: AppColors.navyDark,
    );
  }
}
