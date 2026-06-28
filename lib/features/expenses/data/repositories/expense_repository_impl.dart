import 'package:nasr_isp/features/expenses/data/datasources/expense_remote_data_source.dart';
import 'package:nasr_isp/features/expenses/domain/repositories/expense_repository.dart';
import 'package:nasr_isp/shared/models/models.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;

  ExpenseRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    await remoteDataSource.addExpense(expense);
  }

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    return await remoteDataSource.getExpenses();
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    await remoteDataSource.updateExpense(expense);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await remoteDataSource.deleteExpense(id);
  }
}
