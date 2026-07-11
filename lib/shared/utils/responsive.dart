import 'package:flutter/material.dart';
import 'package:nasr_isp/core/responsive/responsive_layout.dart';
import 'package:nasr_isp/core/responsive/breakpoints.dart';

/// Convenience helpers that delegate to [ResponsiveLayout] static methods
/// and [Breakpoints] constants.
///
/// Usage:
/// ```dart
/// if (Responsive.isMobile(context)) { ... }
/// ```
class Responsive {
  Responsive._();

  /// Returns `true` when the viewport width is in the mobile range (< 768px).
  static bool isMobile(BuildContext context) =>
      ResponsiveLayout.isMobile(context);

  /// Returns `true` when the viewport width is in the tablet range
  /// (768px ≤ width < 1280px).
  static bool isTablet(BuildContext context) =>
      ResponsiveLayout.isTablet(context);

  /// Returns `true` when the viewport width is in the desktop range (≥ 1280px).
  static bool isDesktop(BuildContext context) =>
      ResponsiveLayout.isDesktop(context);

  /// Mobile breakpoint constant (< this value = mobile).
  static const double mobileBreakpoint = Breakpoints.mobile;

  /// Tablet breakpoint constant (< this value = tablet).
  static const double tabletBreakpoint = Breakpoints.tablet;
}
