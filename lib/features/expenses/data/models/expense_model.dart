import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/expenses/domain/entities/expense_entity.dart';

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.title,
    required super.category,
    required super.amount,
    required super.date,
    required super.paidBy,
    super.notes,
    super.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String? ?? '',
      title: (map['title'] ?? map['description'] ?? '') as String,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == (map['category'] as String? ?? ''),
        orElse: () => ExpenseCategory.other,
      ),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      paidBy: map['paidBy'] as String? ?? 'Admin',
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'paidBy': paidBy,
      'notes': notes,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExpenseModel.fromMap({...data, 'id': doc.id});
  }

  factory ExpenseModel.fromEntity(ExpenseEntity entity) {
    return ExpenseModel(
      id: entity.id,
      title: entity.title,
      category: entity.category,
      amount: entity.amount,
      date: entity.date,
      paidBy: entity.paidBy,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  @override
  ExpenseModel copyWith({
    String? id,
    String? title,
    ExpenseCategory? category,
    double? amount,
    DateTime? date,
    String? paidBy,
    String? notes,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paidBy: paidBy ?? this.paidBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}