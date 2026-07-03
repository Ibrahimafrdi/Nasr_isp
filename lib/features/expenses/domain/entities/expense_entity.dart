import 'package:equatable/equatable.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';

class ExpenseEntity extends Equatable {
  final String id;
  final String title;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String paidBy;
  final String? notes;
  final DateTime? createdAt;

  const ExpenseEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.paidBy,
    this.notes,
    this.createdAt,
  });

  String get description => title;

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        amount,
        date,
        paidBy,
        notes,
        createdAt,
      ];

  ExpenseEntity copyWith({
    String? id,
    String? title,
    ExpenseCategory? category,
    double? amount,
    DateTime? date,
    String? paidBy,
    String? notes,
    DateTime? createdAt,
  }) {
    return ExpenseEntity(
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
