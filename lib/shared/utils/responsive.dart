import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';

/// The single source of truth for responsive layout in this app. Every
/// module's layout decision (list-vs-cards, column counts, form layout,
/// dialog style, page padding) derives from here — do not add ad-hoc width
/// checks, and do not introduce a second breakpoint set.
///
/// Mobile:  < 600px
/// Tablet:  600px – <1024px
/// Desktop: >= 1024px
///
/// ## Which API to use
///
/// The window and the shell's content area are different widths — on desktop
/// the sidebar (260px, see `DashboardSidebar`) insets page content. Picking
/// the wrong one is the most common bug in this area, so the rule is:
///
/// * **[Responsive.isMobile] and friends (MediaQuery / window width)** — for
///   widgets that span the whole window and sit outside the shell's content
///   area: dialogs and bottom sheets (they are `Navigator` siblings of
///   `AppShell`), `useSafeArea`, the login page, `AppShell` itself and its
///   chrome (`DashboardTopBar`).
/// * **[ResponsiveBuilder] / [ResponsiveSwitcher] (LayoutBuilder
///   constraints)** — for anything rendered *inside* a page body:
///   table-vs-cards, grid column counts, paired form fields, page padding.
///
/// Tablet always degrades toward the mobile layout, never the desktop one —
/// `AppShell` hides the sidebar below 1024, so a tablet renders page content
/// at full window width, which is exactly where a wide table is worst.
enum DeviceType { mobile, tablet, desktop }

class Responsive {
  Responsive._();

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  static DeviceType deviceTypeForWidth(double width) {
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Uses the ambient window size. Correct for widgets that span the window —
  /// dialogs, bottom sheets, the login page, `AppShell` chrome. For content
  /// nested inside the app shell's sidebar layout use [ResponsiveBuilder] or
  /// [ResponsiveSwitcher] instead, so width comes from local [LayoutBuilder]
  /// constraints rather than the window.
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

  /// Outer padding for a page body. Phones get a tighter gutter — 24px each
  /// side costs 13% of a 360dp screen, which is what pushes several form
  /// action rows into overflow.
  ///
  /// Prefer wrapping the page in `ResponsivePage`, which applies this.
  static EdgeInsets pagePaddingFor(DeviceType type) => switch (type) {
    DeviceType.mobile => const EdgeInsets.all(AppSpacing.lg), // 16
    DeviceType.tablet => const EdgeInsets.all(AppSpacing.xl), // 24
    DeviceType.desktop => const EdgeInsets.all(AppSpacing.xl), // 24
  };

  /// Padding for a card/section *inside* a page body, which already carries
  /// [pagePaddingFor]. Stacking 24 + 32 burns 112px of a 360dp screen.
  static EdgeInsets cardPaddingFor(DeviceType type) => switch (type) {
    DeviceType.mobile => const EdgeInsets.all(AppSpacing.lg), // 16
    DeviceType.tablet => const EdgeInsets.all(AppSpacing.xl), // 24
    DeviceType.desktop => const EdgeInsets.all(AppSpacing.xxl), // 32
  };
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
