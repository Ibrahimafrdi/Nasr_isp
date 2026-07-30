import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';

/// The submit/cancel pair at the bottom of a form.
///
/// Desktop keeps the conventional right-aligned `[Cancel] [Save]` row. Below
/// [Responsive.mobileBreakpoint] the buttons stack full-width with the
/// primary action on top — a side-by-side pair does not fit a phone once the
/// page and card padding are subtracted, and `ElevatedButton`'s theme adds
/// 24dp of horizontal padding per side on top of the label.
///
/// Driven by [LayoutBuilder] rather than `MediaQuery`, so it lays out
/// correctly both in a page body (inset by the shell sidebar on desktop) and
/// inside a full-screen dialog.
class AdaptiveFormActions extends StatelessWidget {
  /// The confirming action — Save, Create, Update.
  final Widget primary;

  /// The dismissing action, usually Cancel. Omitted in dialogs that already
  /// carry a close affordance in their app bar.
  final Widget? secondary;

  /// Height each button is stretched to when stacked. Keeps the tap target
  /// above the 44dp minimum.
  final double mobileButtonHeight;

  const AdaptiveFormActions({
    super.key,
    required this.primary,
    this.secondary,
    this.mobileButtonHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile =
            Responsive.deviceTypeForWidth(constraints.maxWidth) ==
            DeviceType.mobile;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: mobileButtonHeight, child: primary),
              if (secondary != null) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(height: mobileButtonHeight, child: secondary),
              ],
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (secondary != null) ...[
              secondary!,
              const SizedBox(width: AppSpacing.lg),
            ],
            primary,
          ],
        );
      },
    );
  }
}
