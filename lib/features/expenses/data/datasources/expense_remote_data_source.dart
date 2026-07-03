import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/features/expenses/data/models/expense_model.dart';

abstract class ExpenseRemoteDataSource {
  Future<void> addExpense(ExpenseModel expense);
  Future<List<ExpenseModel>> getExpenses();
  Future<void> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final FirebaseFirestore _firestore;

  ExpenseRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('expenses');

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    final docRef = expense.id.isNotEmpty ? _col.doc(expense.id) : _col.doc();
    final modelToSave = expense.id.isNotEmpty
        ? expense
        : expense.copyWith(id: docRef.id);
    await docRef.set(modelToSave.toMap());
  }

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    final snapshot = await _col.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    await _col.doc(expense.id).update(expense.toMap());
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _col.doc(id).delete();
  }
}
