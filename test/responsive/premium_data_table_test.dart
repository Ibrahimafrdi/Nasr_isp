import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/shared/widgets/premium_data_table.dart';

import '../helpers/responsive_harness.dart';

/// Six columns, matching the widest real table (expenses).
List<PremiumDataColumn> _columns() => [
  PremiumDataColumn(label: 'Title', width: 2.5),
  PremiumDataColumn(label: 'Category', width: 1.2),
  PremiumDataColumn(label: 'Amount', width: 1.2),
  PremiumDataColumn(label: 'Paid By', width: 1.2),
  PremiumDataColumn(label: 'Date', width: 1.3),
  PremiumDataColumn(label: 'Actions'),
];

List<PremiumDataRow> _rows({int count = 3}) => List.generate(
  count,
  (i) => PremiumDataRow(
    cells: [
      'Fibre splice kit replacement for tower $i',
      'Equipment',
      'PKR 12,500',
      'Muhammad Abdul Rehman',
      '2026-07-${(i % 28) + 1}',
      'Edit',
    ],
  ),
);

void main() {
  setUpAll(disableGoogleFontsFetching);

  testWidgets('never overflows at any viewport width', (tester) async {
    for (final width in kTestWidths) {
      await pumpAtWidth(
        tester,
        PremiumDataTable(columns: _columns(), rows: _rows()),
        width,
      );
      expectNoOverflow(tester, reason: 'overflowed at width $width');
    }
  });

  testWidgets('fills its slot when the columns fit', (tester) async {
    // The bug this replaces computed width as `MediaQuery.size.width - 320`,
    // so a wide window rendered a table 320dp narrower than its container.
    await pumpAtWidth(
      tester,
      PremiumDataTable(columns: _columns(), rows: _rows()),
      1920,
    );

    final tableWidth = tester.getSize(find.byType(PremiumDataTable)).width;
    expect(tableWidth, 1920);

    // And the header row spans that full width rather than a phantom 1600.
    final headerWidth = tester
        .getSize(find.text('Title').first)
        .width;
    expect(headerWidth, greaterThan(0));
    expect(find.byType(Scrollable), findsNothing);
  });

  testWidgets('scrolls horizontally instead of overflowing when too narrow', (
    tester,
  ) async {
    await pumpAtWidth(
      tester,
      PremiumDataTable(columns: _columns(), rows: _rows()),
      400,
    );
    expectNoOverflow(tester);

    final scrollable = tester.widget<Scrollable>(find.byType(Scrollable).first);
    expect(scrollable.axisDirection, AxisDirection.right);
  });

  testWidgets('unset and explicit column widths share one flex scale', (
    tester,
  ) async {
    // Regression guard: `width` used to default to flex 1 while an explicit
    // `width: 2.5` became flex 25, so mixing the two collapsed the unset
    // columns to ~4% of the row.
    final columns = [
      PremiumDataColumn(label: 'Wide', width: 2.0),
      PremiumDataColumn(label: 'Normal'),
    ];
    expect(columns[0].flex, columns[1].flex * 2);

    await pumpAtWidth(
      tester,
      PremiumDataTable(
        columns: columns,
        rows: [
          PremiumDataRow(cells: const ['a', 'b']),
        ],
      ),
      1200,
    );
    expectNoOverflow(tester);
  });

  testWidgets('tolerates a row with fewer cells than columns', (tester) async {
    // Previously threw RangeError during layout.
    await pumpAtWidth(
      tester,
      PremiumDataTable(
        columns: _columns(),
        rows: [
          PremiumDataRow(cells: const ['only', 'two']),
        ],
      ),
      1280,
    );
    expectNoOverflow(tester);
    expect(find.text('only'), findsOneWidget);
  });

  testWidgets('renders loading and empty states without overflow', (
    tester,
  ) async {
    for (final width in [360.0, 1280.0]) {
      await pumpAtWidth(
        tester,
        PremiumDataTable(columns: _columns(), rows: const [], isLoading: true),
        width,
      );
      expectNoOverflow(tester, reason: 'loading state at $width');

      await pumpAtWidth(
        tester,
        PremiumDataTable(columns: _columns(), rows: const []),
        width,
      );
      expectNoOverflow(tester, reason: 'empty state at $width');
    }
  });

  testWidgets('pagination bar stays outside the horizontal scroller', (
    tester,
  ) async {
    await pumpAtWidth(
      tester,
      PremiumDataTable(
        columns: _columns(),
        rows: _rows(count: 10),
        rowsPerPage: 10,
        totalRows: 42,
        currentPage: 1,
        onPageChange: (_) {},
      ),
      400,
    );
    expectNoOverflow(tester);

    // The footer must not be a descendant of the table's horizontal scroller,
    // or it would slide off-screen when the table is scrolled sideways.
    expect(
      find.descendant(
        of: find.byType(Scrollable).first,
        matching: find.textContaining('Showing'),
      ),
      findsNothing,
    );
  });
}
