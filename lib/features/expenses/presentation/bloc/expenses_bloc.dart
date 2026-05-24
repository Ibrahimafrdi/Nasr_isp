import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/shared/models/models.dart';

abstract class ExpensesEvent extends Equatable {
  const ExpensesEvent();

  @override
  List<Object?> get props => [];
}

class LoadExpensesEvent extends ExpensesEvent {
  final int page;
  const LoadExpensesEvent({this.page = 1});

  @override
  List<Object?> get props => [page];
}

abstract class ExpensesState extends Equatable {
  const ExpensesState();

  @override
  List<Object?> get props => [];
}

class ExpensesInitial extends ExpensesState {
  const ExpensesInitial();
}

class ExpensesLoading extends ExpensesState {
  const ExpensesLoading();
}

class ExpensesLoaded extends ExpensesState {
  final List<ExpenseModel> expenses;
  final double totalExpenses;
  final int currentPage;
  final int totalPages;

  const ExpensesLoaded({
    required this.expenses,
    required this.totalExpenses,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  List<Object?> get props => [expenses, totalExpenses, currentPage, totalPages];
}

class ExpensesBloc extends Bloc<ExpensesEvent, ExpensesState> {
  ExpensesBloc() : super(const ExpensesInitial()) {
    on<LoadExpensesEvent>(_onLoadExpenses);
  }

  Future<void> _onLoadExpenses(
    LoadExpensesEvent event,
    Emitter<ExpensesState> emit,
  ) async {
    emit(const ExpensesLoading());
    await Future.delayed(const Duration(milliseconds: 500));

    final allExpenses = _generateMockExpenses();
    final totalPages = (allExpenses.length / AppConstants.itemsPerPage).ceil();
    final start = (event.page - 1) * AppConstants.itemsPerPage;
    final end = (start + AppConstants.itemsPerPage)
        .clamp(0, allExpenses.length)
        .toInt();
    final paginated = allExpenses.sublist(start, end);

    final totalExpenses = allExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );

    emit(
      ExpensesLoaded(
        expenses: paginated,
        totalExpenses: totalExpenses,
        currentPage: event.page,
        totalPages: totalPages,
      ),
    );
  }

  List<ExpenseModel> _generateMockExpenses() {
    final baseDate = DateTime.now();
    final categories = ExpenseCategory.values;
    return List.generate(100, (i) {
      return ExpenseModel(
        id: 'exp_$i',
        description: 'Expense ${i + 1}',
        category: categories[i % categories.length],
        amount: (5000 + (i * 500)).toDouble(),
        date: baseDate.subtract(Duration(days: i)),
        notes: 'Sample note',
        createdAt: baseDate.subtract(Duration(days: i)),
      );
    });
  }
}
