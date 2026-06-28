import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/shared/models/models.dart';

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
    await _col.doc(expense.id).set({
      'description': expense.description,
      'category': expense.category.name,
      'amount': expense.amount,
      'date': Timestamp.fromDate(expense.date),
      'notes': expense.notes,
      'attachmentUrl': expense.attachmentUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    final snapshot = await _col.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ExpenseModel(
        id: doc.id,
        description: data['description'] as String,
        category: ExpenseCategory.values.firstWhere(
          (e) => e.name == data['category'],
          orElse: () => ExpenseCategory.equipment,
        ),
        amount: (data['amount'] as num).toDouble(),
        date: (data['date'] as Timestamp).toDate(),
        notes: data['notes'] as String?,
        attachmentUrl: data['attachmentUrl'] as String?,
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    await _col.doc(expense.id).update({
      'description': expense.description,
      'category': expense.category.name,
      'amount': expense.amount,
      'date': Timestamp.fromDate(expense.date),
      'notes': expense.notes,
      'attachmentUrl': expense.attachmentUrl,
    });
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _col.doc(id).delete();
  }
}
