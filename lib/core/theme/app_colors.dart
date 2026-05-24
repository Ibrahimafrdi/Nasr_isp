import 'package:flutter/material.dart';

class AppColors {
  // Premium Navy & Blue Palette
  static const Color navyDark = Color(0xFF0F1419); // Deep navy sidebar
  static const Color navyMedium = Color(0xFF1A202C); // Medium navy
  static const Color navy = Color(0xFF2D3748); // Standard navy
  static const Color navyLight = Color(0xFF4A5568); // Light navy

  // Primary Blues
  static const Color primaryBlue = Color(0xFF0F62FE); // Royal blue
  static const Color blueAccent = Color(0xFF0074E4); // Electric blue
  static const Color lightBlue = Color(0xFF0043CE); // Darker blue
  static const Color skyBlue = Color(0xFFE0F2FE); // Sky blue tint

  // Status Colors
  static const Color successGreen = Color(0xFF10B981); // Emerald green
  static const Color warningOrange = Color(0xFFF59E0B); // Warm orange
  static const Color errorRed = Color(0xFFEF4444); // Deep red
  static const Color infoBlue = Color(0xFF0074E4); // Info blue
  static const Color pendingYellow = Color(0xFFFCD34D); // Pending yellow

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFBFC);
  static const Color lightGray = Color(0xFFE5E7EB);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color darkGray = Color(0xFF6B7280);
  static const Color charcoal = Color(0xFF374151);
  static const Color black = Color(0xFF1F2937);

  // Gradients
  static const List<Color> blueGradient = [
    Color(0xFF0F62FE),
    Color(0xFF0074E4),
  ];
  static const List<Color> greenGradient = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];
  static const List<Color> orangeGradient = [
    Color(0xFFF59E0B),
    Color(0xFFD97706),
  ];
  static const List<Color> purpleGradient = [
    Color(0xFF8B5CF6),
    Color(0xFF7C3AED),
  ];
  static const List<Color> redGradient = [Color(0xFFEF4444), Color(0xFFDC2626)];

  // Semantic Colors for ISP Operations
  static const Color networkActive = Color(0xFF10B981);
  static const Color networkInactive = Color(0xFFEF4444);
  static const Color networkPending = Color(0xFFFCD34D);
  static const Color networkOffline = Color(0xFF9CA3AF);

  // Revenue/Financial
  static const Color revenueGreen = Color(0xFF10B981);
  static const Color expenseRed = Color(0xFFEF4444);
  static const Color profitBlue = Color(0xFF0F62FE);

  // Shadow Colors
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowDark = Color(0x26000000);

  // Overlay
  static const Color overlay25 = Color(0x40000000);
  static const Color overlay50 = Color(0x80000000);
}
