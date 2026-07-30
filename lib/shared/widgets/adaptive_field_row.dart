import 'package:flutter/material.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';

/// A row of form fields that stacks vertically once the available width drops
/// below [Responsive.mobileBreakpoint].
///
/// Two fields side by side inside a dialog leave roughly 130dp each on a
/// phone, which truncates both the label and the value. Stacking is the only
/// layout that stays legible.
///
/// Uses [LayoutBuilder] rather than `MediaQuery` so the decision follows the
/// actual slot — correct both in a page body (inset by the shell sidebar on
/// desktop) and inside a full-screen dialog.
class AdaptiveFieldRow extends StatelessWidget {
  final List<Widget> children;

  /// Gap between fields — horizontal when in a row, vertical when stacked.
  final double spacing;

  const AdaptiveFieldRow({
    super.key,
    required this.children,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile =
            Responsive.deviceTypeForWidth(constraints.maxWidth) ==
            DeviceType.mobile;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}
