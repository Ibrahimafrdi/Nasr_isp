import 'package:nasr_isp/shared/models/models.dart';

abstract class ExpenseRepository {
  Future<void> addExpense(ExpenseModel expense);
  Future<List<ExpenseModel>> getExpenses();
  Future<void> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
}
