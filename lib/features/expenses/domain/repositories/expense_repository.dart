import 'package:nasr_isp/features/expenses/domain/entities/expense_entity.dart';

abstract class ExpenseRepository {
  Future<void> addExpense(ExpenseEntity expense);
  Future<List<ExpenseEntity>> getExpenses();
  Future<void> updateExpense(ExpenseEntity expense);
  Future<void> deleteExpense(String id);
}
