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
  final String searchQuery;
  final List<String> filterCategories;

  const LoadExpensesEvent({
    this.page = 1,
    this.searchQuery = '',
    this.filterCategories = const [],
  });

  @override
  List<Object?> get props => [page, searchQuery, filterCategories];
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

    var allExpenses = _generateMockExpenses();

    if (event.searchQuery.isNotEmpty) {
      final q = event.searchQuery.toLowerCase();
      allExpenses = allExpenses
          .where((e) => e.description.toLowerCase().contains(q))
          .toList();
    }

    if (event.filterCategories.isNotEmpty) {
      allExpenses = allExpenses
          .where((e) => event.filterCategories.contains(e.category.label))
          .toList();
    }

    final totalPages = allExpenses.isEmpty
        ? 1
        : (allExpenses.length / AppConstants.itemsPerPage).ceil();

    final start = (event.page - 1) * AppConstants.itemsPerPage;
    final end = (start + AppConstants.itemsPerPage)
        .clamp(0, allExpenses.length)
        .toInt();
    final paginated = start < allExpenses.length
        ? allExpenses.sublist(start, end)
        : <ExpenseModel>[];

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
