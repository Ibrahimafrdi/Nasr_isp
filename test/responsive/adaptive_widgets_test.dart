import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/shared/widgets/adaptive_field_row.dart';
import 'package:nasr_isp/shared/widgets/adaptive_form_actions.dart';
import 'package:nasr_isp/shared/widgets/adaptive_form_dialog.dart';

import '../helpers/responsive_harness.dart';

/// A form body roughly the size of the real Add-Expense dialog.
Widget _formBody() => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    const TextField(decoration: InputDecoration(labelText: 'Expense Title')),
    const SizedBox(height: 16),
    AdaptiveFieldRow(
      children: const [
        TextField(decoration: InputDecoration(labelText: 'Category')),
        TextField(decoration: InputDecoration(labelText: 'Amount (PKR)')),
      ],
    ),
    const SizedBox(height: 16),
    AdaptiveFieldRow(
      children: const [
        TextField(decoration: InputDecoration(labelText: 'Date')),
        TextField(decoration: InputDecoration(labelText: 'Paid By')),
      ],
    ),
  ],
);

Widget _dialogHost() => Builder(
  builder: (context) => ElevatedButton(
    onPressed: () => showAppFormDialog(
      context: context,
      builder: (_) => AdaptiveFormDialog(
        title: 'Record Operating Expense',
        desktopWidth: 480,
        content: _formBody(),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Cancel')),
          ElevatedButton(onPressed: () {}, child: const Text('Record Expense')),
        ],
      ),
    ),
    child: const Text('open'),
  ),
);

void main() {
  setUpAll(disableGoogleFontsFetching);

  group('AdaptiveFormDialog', () {
    testWidgets('goes full-screen on a phone', (tester) async {
      await pumpAtWidth(tester, _dialogHost(), 360);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(Scaffold), findsWidgets);
      // Title in the app bar, close button, and the pinned bottom action.
      expect(find.text('Record Operating Expense'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('Record Expense'), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('stays an AlertDialog on desktop', (tester) async {
      await pumpAtWidth(tester, _dialogHost(), 1280);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
      // Both actions are present on desktop, not just the primary one.
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Record Expense'), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('constrains its body to desktopWidth on desktop', (
      tester,
    ) async {
      await pumpAtWidth(tester, _dialogHost(), 1280);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final title = tester.getSize(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Expense Title'),
        ),
      );
      expect(title.width, lessThanOrEqualTo(480));
    });

    testWidgets('close button is disabled while canClose is false', (
      tester,
    ) async {
      await pumpAtWidth(
        tester,
        const AdaptiveFormDialog(
          title: 'Saving',
          content: SizedBox(height: 20),
          canClose: false,
        ),
        360,
      );
      final closeButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(closeButton.onPressed, isNull);
    });
  });

  group('AdaptiveFieldRow', () {
    Widget row() => AdaptiveFieldRow(
      children: const [Text('first'), Text('second')],
    );

    testWidgets('stacks vertically below the mobile breakpoint', (
      tester,
    ) async {
      await pumpAtWidth(tester, row(), 360);
      expectNoOverflow(tester);

      final first = tester.getTopLeft(find.text('first'));
      final second = tester.getTopLeft(find.text('second'));
      expect(second.dy, greaterThan(first.dy));
      expect(second.dx, first.dx);
    });

    testWidgets('lays out side by side at tablet width and up', (tester) async {
      await pumpAtWidth(tester, row(), 900);
      expectNoOverflow(tester);

      final first = tester.getTopLeft(find.text('first'));
      final second = tester.getTopLeft(find.text('second'));
      expect(second.dx, greaterThan(first.dx));
      expect(second.dy, first.dy);
    });

    testWidgets('never overflows at any width', (tester) async {
      for (final width in kTestWidths) {
        await pumpAtWidth(
          tester,
          AdaptiveFieldRow(
            children: const [
              TextField(decoration: InputDecoration(labelText: 'Category')),
              TextField(decoration: InputDecoration(labelText: 'Amount')),
              TextField(decoration: InputDecoration(labelText: 'Paid By')),
            ],
          ),
          width,
        );
        expectNoOverflow(tester, reason: 'AdaptiveFieldRow at width $width');
      }
    });
  });

  group('AdaptiveFormActions', () {
    Widget actions() => AdaptiveFormActions(
      secondary: OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
      primary: ElevatedButton(
        onPressed: () {},
        child: const Text('Create Customer & Installation'),
      ),
    );

    testWidgets('stacks full-width on a phone, primary first', (tester) async {
      await pumpAtWidth(tester, actions(), 360);
      expectNoOverflow(tester);

      final primary = tester.getTopLeft(
        find.text('Create Customer & Installation'),
      );
      final secondary = tester.getTopLeft(find.text('Cancel'));
      expect(primary.dy, lessThan(secondary.dy));

      // Each button is at least the 44dp minimum touch target tall.
      expect(
        tester.getSize(find.byType(ElevatedButton)).height,
        greaterThanOrEqualTo(44),
      );
    });

    testWidgets('is a right-aligned row on desktop, secondary first', (
      tester,
    ) async {
      await pumpAtWidth(tester, actions(), 1280);
      expectNoOverflow(tester);

      final primary = tester.getTopLeft(
        find.text('Create Customer & Installation'),
      );
      final secondary = tester.getTopLeft(find.text('Cancel'));
      expect(secondary.dx, lessThan(primary.dx));
      expect(secondary.dy, primary.dy);
    });

    testWidgets('renders without a secondary action', (tester) async {
      await pumpAtWidth(
        tester,
        AdaptiveFormActions(
          primary: ElevatedButton(onPressed: () {}, child: const Text('Save')),
        ),
        360,
      );
      expectNoOverflow(tester);
      expect(find.text('Save'), findsOneWidget);
    });
  });
}
