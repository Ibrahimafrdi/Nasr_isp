import 'package:nasr_isp/features/expenses/data/datasources/expense_remote_data_source.dart';
import 'package:nasr_isp/features/expenses/data/models/expense_model.dart';
import 'package:nasr_isp/features/expenses/domain/entities/expense_entity.dart';
import 'package:nasr_isp/features/expenses/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;

  ExpenseRepositoryImpl({required this.remoteDataSource});

  ExpenseModel _toModel(ExpenseEntity entity) => ExpenseModel.fromEntity(entity);

  @override
  Future<void> addExpense(ExpenseEntity expense) async {
    await remoteDataSource.addExpense(_toModel(expense));
  }

  @override
  Future<List<ExpenseEntity>> getExpenses() async {
    return await remoteDataSource.getExpenses();
  }

  @override
  Future<void> updateExpense(ExpenseEntity expense) async {
    await remoteDataSource.updateExpense(_toModel(expense));
  }

  @override
  Future<void> deleteExpense(String id) async {
    await remoteDataSource.deleteExpense(id);
  }
}
