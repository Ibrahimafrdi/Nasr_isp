import 'package:equatable/equatable.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_issue_entity.dart';

/// Whether an issue contributes to financial sales aggregates.
///
/// A direct sale is a document where `purpose == StockIssuePurpose.sale` and
/// `salePrice != null`.
/// Other purposes (tower, replacement, damagedLost, other) are NOT sales and
/// must never count as revenue or profit.
/// Legacy docs with `purpose == StockIssuePurpose.sale` but `salePrice == null`
/// must be ignored, not counted as 0.
bool isFinanciallyCountableSale(StockIssueEntity issue) =>
    issue.purpose == StockIssuePurpose.sale && issue.salePrice != null;

/// Single sale's financial position:
///   revenue = salePrice * quantity
///   cost    = unitCost  * quantity
///   profit  = revenue   - cost
///
/// Uses the stored [StockIssueEntity.unitCost] snapshot, never the live inventory item's
/// current unitCost, preserving financial history.
MoneyLine stockIssueMoney(StockIssueEntity issue) {
  if (!isFinanciallyCountableSale(issue)) return MoneyLine.zero;
  return MoneyLine(
    amountBilled: issue.salePrice! * issue.quantity,
    costIncurred: issue.unitCost * issue.quantity,
  );
}

/// Aggregate totals for product stock sales.
class StockSalesTotals extends Equatable {
  final MoneyLine money;
  final int salesCount;
  final int unitsSold;

  const StockSalesTotals({
    required this.money,
    required this.salesCount,
    required this.unitsSold,
  });

  static const StockSalesTotals zero = StockSalesTotals(
    money: MoneyLine.zero,
    salesCount: 0,
    unitsSold: 0,
  );

  double get revenue => money.amountBilled;
  double get cost => money.costIncurred;
  double get profit => money.profit;

  StockSalesTotals operator +(StockSalesTotals other) => StockSalesTotals(
        money: money + other.money,
        salesCount: salesCount + other.salesCount,
        unitsSold: unitsSold + other.unitsSold,
      );

  @override
  List<Object?> get props => [money, salesCount, unitsSold];
}

/// Computes [StockSalesTotals] over [issues].
StockSalesTotals stockSalesTotals(Iterable<StockIssueEntity> issues) {
  final sales = issues.where(isFinanciallyCountableSale);
  final money = MoneyLine.sum(sales.map(stockIssueMoney));
  final unitsSold = sales.fold<int>(0, (sum, s) => sum + s.quantity);
  final salesCount = sales.length;

  return StockSalesTotals(
    money: money,
    salesCount: salesCount,
    unitsSold: unitsSold,
  );
}

/// Direct sales whose `date` falls in the calendar month containing [month].
List<StockIssueEntity> salesInMonth(
  Iterable<StockIssueEntity> issues,
  DateTime month,
) =>
    issues.where((s) {
      if (!isFinanciallyCountableSale(s)) return false;
      return s.date.year == month.year && s.date.month == month.month;
    }).toList();

