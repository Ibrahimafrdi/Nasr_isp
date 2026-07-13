import 'package:flutter/material.dart';

/// Canonical breakpoints for the whole app. Every module's responsive
/// layout decisions (list-vs-cards, column counts, form layout, dialog
/// style, etc.) should be derived from this single source of truth
/// instead of ad-hoc width checks.
///
/// Mobile:  < 600px
/// Tablet:  600px – 1024px
/// Desktop: > 1024px
enum DeviceType { mobile, tablet, desktop }

class Responsive {
  Responsive._();

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  static DeviceType deviceTypeForWidth(double width) {
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width <= tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Uses the ambient window size. Correct for top-level scaffolds
  /// (login page, dialogs, bottom sheets) where content spans the full
  /// window. For content nested inside the app shell's sidebar layout,
  /// prefer [ResponsiveBuilder]/[isMobileOf] etc. with a [BuildContext]
  /// from inside the constrained content area, or use [ResponsiveBuilder]
  /// directly so width comes from local [LayoutBuilder] constraints.
  static DeviceType deviceTypeOf(BuildContext context) =>
      deviceTypeForWidth(MediaQuery.sizeOf(context).width);

  static bool isMobile(BuildContext context) =>
      deviceTypeOf(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      deviceTypeOf(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      deviceTypeOf(context) == DeviceType.desktop;

  /// True on mobile or tablet — the common "not desktop" check used for
  /// switching a table to a card list, or a dialog to a full-screen/sheet.
  static bool isMobileOrTablet(BuildContext context) =>
      deviceTypeOf(context) != DeviceType.desktop;
}

/// Rebuilds using the width of its own [LayoutBuilder] constraints
/// (not the window) — use this inside the app shell's content area, where
/// the available width is narrower than the full window due to the
/// sidebar/drawer.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = Responsive.deviceTypeForWidth(constraints.maxWidth);
        return builder(context, deviceType);
      },
    );
  }
}

/// Convenience widget for the common mobile/tablet/desktop switch, driven
/// by local [LayoutBuilder] constraints. If [tablet] is omitted, tablet
/// width falls back to [mobile] (matches the "cards on mobile/tablet,
/// table on desktop" rule used across list pages).
class ResponsiveSwitcher extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveSwitcher({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = Responsive.deviceTypeForWidth(constraints.maxWidth);
        switch (deviceType) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
            return desktop;
        }
      },
    );
  }
}
