import 'package:nasr_isp/features/inventory/domain/entities/stock_issue_entity.dart';
import 'package:nasr_isp/features/inventory/domain/repositories/inventory_repository.dart';

class IssueStock {
  final InventoryRepository repository;

  IssueStock(this.repository);

  Future<void> call(StockIssueEntity issue) => repository.issueStock(issue);
}
