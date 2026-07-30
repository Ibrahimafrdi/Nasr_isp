import 'package:flutter/material.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';

/// A form dialog that becomes a full-screen page on phones.
///
/// On desktop this is a plain [AlertDialog] constrained to [desktopWidth].
/// On mobile a fixed-width dialog is clamped by `AlertDialog`'s inset padding
/// into a ~280dp column, which is unusable for anything with paired fields —
/// so mobile gets [Dialog.fullscreen] wrapping a [Scaffold]: title and close
/// button in the app bar, scrolling body, and one full-width action pinned to
/// the bottom.
///
/// This is a widget rather than a helper function so callers keep their
/// existing `showDialog` + `StatefulBuilder` + closure-captured state and
/// change only the `AlertDialog(` line.
///
/// Launch it with [showAppFormDialog], which sets `useSafeArea` correctly.
///
/// Keyboard handling is deliberately left to [Scaffold]: its
/// `resizeToAvoidBottomInset` defaults to true, so the body shrinks and
/// [bottomNavigationBar] rides above the keyboard. Adding manual
/// `MediaQuery.viewInsets` padding on top of that double-counts and pushes
/// the action button off-screen.
class AdaptiveFormDialog extends StatelessWidget {
  /// Shown in the `AlertDialog` title on desktop and the `AppBar` on mobile.
  final String title;

  /// The form body. Pass the bare `Form`/`Column` — this widget supplies the
  /// width constraint, scroll view and padding for each layout.
  final Widget content;

  /// Desktop dialog actions, conventionally `[Cancel, Save]`.
  final List<Widget> actions;

  /// The single full-width button pinned to the bottom on mobile. Defaults to
  /// the last entry in [actions] — usually the primary/save action.
  final Widget? mobileAction;

  /// Width of the desktop dialog body.
  final double desktopWidth;

  /// Invoked by the mobile close button. Pass `null` to disable dismissal
  /// (e.g. while a save is in flight); defaults to popping the route.
  final VoidCallback? onClose;

  /// Whether the close affordance is enabled. Separate from [onClose] so the
  /// default pop behaviour can still be disabled during a save.
  final bool canClose;

  const AdaptiveFormDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.mobileAction,
    this.desktopWidth = 520,
    this.onClose,
    this.canClose = true,
  });

  @override
  Widget build(BuildContext context) {
    // MediaQuery, not LayoutBuilder: a dialog is a Navigator sibling of
    // AppShell and spans the whole window, so the sidebar never insets it.
    final isMobile = Responsive.isMobile(context);
    final close = canClose
        ? (onClose ?? () => Navigator.of(context).pop())
        : null;

    if (isMobile) {
      final action =
          mobileAction ?? (actions.isNotEmpty ? actions.last : null);

      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(title),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: close,
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
          bottomNavigationBar: action == null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(height: 48, child: action),
                  ),
                ),
        ),
      );
    }

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: desktopWidth,
        child: SingleChildScrollView(child: content),
      ),
      actions: actions,
    );
  }
}

/// Opens an [AdaptiveFormDialog].
///
/// Named `showAppFormDialog` rather than `showAdaptiveDialog` to avoid
/// colliding with Flutter's own API of that name.
///
/// The only thing this adds over `showDialog` is `useSafeArea: false` on
/// mobile — the full-screen variant renders its own [Scaffold] and
/// [SafeArea], and an outer safe area would inset it twice.
Future<T?> showAppFormDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    useSafeArea: !Responsive.isMobile(context),
    builder: builder,
  );
}
