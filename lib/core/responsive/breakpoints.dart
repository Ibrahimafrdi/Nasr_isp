/// Central breakpoint constants for NASR ISP responsive system.
///
/// These align with the [ResponsiveBreakpoints] configuration in main.dart
/// and with Flutter's [LayoutBuilder] / [MediaQuery] usage throughout the app.
class Breakpoints {
  Breakpoints._();

  /// Screen width at which mobile layout transitions to tablet.
  static const double mobile = 768.0;

  /// Screen width at which tablet layout transitions to desktop.
  static const double tablet = 1280.0;

  /// Maximum content width — anything wider is capped.
  static const double maxContent = 1920.0;

  // Sidebar widths
  static const double sidebarExpanded = 260.0;
  static const double sidebarCollapsed = 80.0;
}
