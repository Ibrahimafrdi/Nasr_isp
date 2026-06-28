import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// A responsive layout widget that builds a different child widget based on
/// the available screen width using [LayoutBuilder].
///
/// Usage:
/// ```dart
/// ResponsiveLayout(
///   mobile: MobileView(),
///   tablet: TabletView(),   // optional — falls back to desktop
///   desktop: DesktopView(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  /// Widget displayed on screens narrower than [Breakpoints.mobile] (< 768px).
  final Widget mobile;

  /// Widget displayed on tablet screens ([Breakpoints.mobile] ≤ width < [Breakpoints.tablet]).
  /// If null, [desktop] is used as a fallback.
  final Widget? tablet;

  /// Widget displayed on screens >= [Breakpoints.tablet] (≥ 1280px).
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  /// Returns true when the current available width is in the mobile range.
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < Breakpoints.mobile;

  /// Returns true when the current available width is in the tablet range.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.mobile && width < Breakpoints.tablet;
  }

  /// Returns true when the current available width is in the desktop range.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.tablet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= Breakpoints.tablet) {
          return desktop;
        } else if (width >= Breakpoints.mobile) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}
