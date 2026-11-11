import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_issue_entity.dart';
import 'package:nasr_isp/features/inventory/domain/utils/stock_sales_aggregates.dart';

void main() {
  group('stock_sales_aggregates', () {
    test('Acceptance 1: sale of 1 item, salePrice 6500, unitCost 5000 adds Rs 1500 profit and Rs 6500 revenue', () {
      final issue = StockIssueEntity(
        id: 's1',
        itemId: 'item1',
        itemName: 'Fiber Router',
        quantity: 1,
        unitCost: 5000,
        salePrice: 6500,
        purpose: StockIssuePurpose.sale,
        buyerName: 'Customer A',
        date: DateTime(2026, 9, 5),
        issuedBy: 'Admin',
      );

      final totals = stockSalesTotals([issue]);
      expect(totals.revenue, 6500.0);
      expect(totals.cost, 5000.0);
      expect(totals.profit, 1500.0);
      expect(totals.salesCount, 1);
      expect(totals.unitsSold, 1);
    });

    test('Acceptance 2: sale of 2 items at 800 each with unitCost 500 adds Rs 600 profit and Rs 1600 revenue', () {
      final issue = StockIssueEntity(
        id: 's2',
        itemId: 'item2',
        itemName: 'ONU',
        quantity: 2,
        unitCost: 500,
        salePrice: 800,
        purpose: StockIssuePurpose.sale,
        buyerName: 'Customer B',
        date: DateTime(2026, 9, 8),
        issuedBy: 'Admin',
      );

      final totals = stockSalesTotals([issue]);
      expect(totals.revenue, 1600.0);
      expect(totals.cost, 1000.0);
      expect(totals.profit, 600.0);
      expect(totals.salesCount, 1);
      expect(totals.unitsSold, 2);
    });

    test('Acceptance 3: tower issue of 3 items adds Rs 0 revenue and Rs 0 profit', () {
      final issue = StockIssueEntity(
        id: 't1',
        itemId: 'item3',
        itemName: 'Splicing Box',
        quantity: 3,
        unitCost: 700,
        purpose: StockIssuePurpose.tower,
        towerName: 'Tower North',
        date: DateTime(2026, 9, 10),
        issuedBy: 'Admin',
      );

      final totals = stockSalesTotals([issue]);
      expect(totals.revenue, 0.0);
      expect(totals.cost, 0.0);
      expect(totals.profit, 0.0);
      expect(totals.salesCount, 0);
      expect(totals.unitsSold, 0);
    });

    test('Non-sale purposes (replacement, damagedLost, other) are never counted as sales', () {
      final issues = [
        StockIssueEntity(
          id: 'rep',
          itemId: 'i1',
          itemName: 'Item',
          quantity: 2,
          unitCost: 300,
          purpose: StockIssuePurpose.replacement,
          date: DateTime(2026, 9, 10),
          issuedBy: 'Admin',
        ),
        StockIssueEntity(
          id: 'dmg',
          itemId: 'i2',
          itemName: 'Item',
          quantity: 1,
          unitCost: 500,
          purpose: StockIssuePurpose.damagedLost,
          date: DateTime(2026, 9, 10),
          issuedBy: 'Admin',
        ),
        StockIssueEntity(
          id: 'oth',
          itemId: 'i3',
          itemName: 'Item',
          quantity: 4,
          unitCost: 100,
          purpose: StockIssuePurpose.other,
          date: DateTime(2026, 9, 10),
          issuedBy: 'Admin',
        ),
      ];

      final totals = stockSalesTotals(issues);
      expect(totals.revenue, 0.0);
      expect(totals.cost, 0.0);
      expect(totals.profit, 0.0);
      expect(totals.salesCount, 0);
      expect(totals.unitsSold, 0);
    });

    test('Legacy doc with purpose == sale but salePrice == null is ignored, not counted as 0', () {
      final issue = StockIssueEntity(
        id: 'legacy',
        itemId: 'item1',
        itemName: 'Old Sale',
        quantity: 2,
        unitCost: 400,
        salePrice: null, // Legacy doc without salePrice
        purpose: StockIssuePurpose.sale,
        buyerName: 'Old Buyer',
        date: DateTime(2026, 9, 5),
        issuedBy: 'Admin',
      );

      final totals = stockSalesTotals([issue]);
      expect(totals.revenue, 0.0);
      expect(totals.cost, 0.0);
      expect(totals.profit, 0.0);
      expect(totals.salesCount, 0);
      expect(totals.unitsSold, 0);
    });

    test('Acceptance 4: sale dated last month appears only in last month figures', () {
      final lastMonthSale = StockIssueEntity(
        id: 's_aug',
        itemId: 'item1',
        itemName: 'Router',
        quantity: 1,
        unitCost: 5000,
        salePrice: 6500,
        purpose: StockIssuePurpose.sale,
        buyerName: 'Buyer 1',
        date: DateTime(2026, 8, 25),
        issuedBy: 'Admin',
      );
      final thisMonthSale = StockIssueEntity(
        id: 's_sep',
        itemId: 'item2',
        itemName: 'ONU',
        quantity: 1,
        unitCost: 1000,
        salePrice: 1500,
        purpose: StockIssuePurpose.sale,
        buyerName: 'Buyer 2',
        date: DateTime(2026, 9, 2),
        issuedBy: 'Admin',
      );

      final allIssues = [lastMonthSale, thisMonthSale];

      final augSales = salesInMonth(allIssues, DateTime(2026, 8, 1));
      expect(augSales, hasLength(1));
      expect(augSales.single.id, 's_aug');
      expect(stockSalesTotals(augSales).profit, 1500.0);

      final sepSales = salesInMonth(allIssues, DateTime(2026, 9, 1));
      expect(sepSales, hasLength(1));
      expect(sepSales.single.id, 's_sep');
      expect(stockSalesTotals(sepSales).profit, 500.0);
    });

    test('Acceptance 6: changing an item unitCost afterwards does not change old sales profit', () {
      // The issue stores unitCost snapshot = 5000 at time of sale.
      final oldSale = StockIssueEntity(
        id: 's_old',
        itemId: 'item1',
        itemName: 'Router',
        quantity: 1,
        unitCost: 5000, // snapshot at time of sale
        salePrice: 6500,
        purpose: StockIssuePurpose.sale,
        buyerName: 'Buyer',
        date: DateTime(2026, 5, 10),
        issuedBy: 'Admin',
      );

      // Even if item current unit cost is now 7000 or 4000, the sale snapshot unitCost (5000) is used.
      final totals = stockSalesTotals([oldSale]);
      expect(totals.cost, 5000.0);
      expect(totals.profit, 1500.0);
    });

    test('Acceptance 8: month with no sales shows Rs 0 for product sales with no error', () {
      final totals = stockSalesTotals([]);
      expect(totals.revenue, 0.0);
      expect(totals.cost, 0.0);
      expect(totals.profit, 0.0);
      expect(totals.salesCount, 0);
      expect(totals.unitsSold, 0);
      expect(totals, equals(StockSalesTotals.zero));
    });
  });
}

