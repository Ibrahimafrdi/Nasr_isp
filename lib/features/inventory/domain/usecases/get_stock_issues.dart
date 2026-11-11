import 'package:nasr_isp/features/inventory/domain/entities/stock_issue_entity.dart';
import 'package:nasr_isp/features/inventory/domain/repositories/inventory_repository.dart';

class GetStockIssues {
  final InventoryRepository repository;

  GetStockIssues(this.repository);

  Future<List<StockIssueEntity>> call({
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      repository.getStockIssues(startDate: startDate, endDate: endDate);
}
