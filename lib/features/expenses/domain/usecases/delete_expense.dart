import 'package:nasr_isp/features/expenses/domain/repositories/expense_repository.dart';

class DeleteExpense {
  final ExpenseRepository repository;

  DeleteExpense(this.repository);

  Future<void> call(String id) async {
    return repository.deleteExpense(id);
  }
}
