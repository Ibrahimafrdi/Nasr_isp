import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/expenses/domain/entities/expense_entity.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/add_expense.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/delete_expense.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/get_expenses.dart';
import 'package:nasr_isp/features/expenses/domain/usecases/update_expense.dart';

// ── Events ───────────────────────────────────────────────────────────────────

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

class AddExpenseEvent extends ExpensesEvent {
  final ExpenseEntity expense;

  const AddExpenseEvent(this.expense);

  @override
  List<Object?> get props => [expense];
}

class UpdateExpenseEvent extends ExpensesEvent {
  final ExpenseEntity expense;

  const UpdateExpenseEvent(this.expense);

  @override
  List<Object?> get props => [expense];
}

class DeleteExpenseEvent extends ExpensesEvent {
  final String expenseId;

  const DeleteExpenseEvent(this.expenseId);

  @override
  List<Object?> get props => [expenseId];
}

// ── States ───────────────────────────────────────────────────────────────────

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
  final List<ExpenseEntity> expenses;
  final double totalExpenses;
  final double totalThisMonth;
  final int currentPage;
  final int totalPages;
  final String searchQuery;
  final List<String> filterCategories;

  const ExpensesLoaded({
    required this.expenses,
    required this.totalExpenses,
    required this.totalThisMonth,
    required this.currentPage,
    required this.totalPages,
    this.searchQuery = '',
    this.filterCategories = const [],
  });

  @override
  List<Object?> get props => [
        expenses,
        totalExpenses,
        totalThisMonth,
        currentPage,
        totalPages,
        searchQuery,
        filterCategories,
      ];
}

class ExpensesError extends ExpensesState {
  final String message;

  const ExpensesError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ── BLoC Implementation ──────────────────────────────────────────────────────

class ExpensesBloc extends Bloc<ExpensesEvent, ExpensesState> {
  final GetExpenses getExpenses;
  final AddExpense addExpense;
  final UpdateExpense updateExpense;
  final DeleteExpense deleteExpense;

  ExpensesBloc({
    required this.getExpenses,
    required this.addExpense,
    required this.updateExpense,
    required this.deleteExpense,
  }) : super(const ExpensesInitial()) {
    on<LoadExpensesEvent>(_onLoadExpenses);
    on<AddExpenseEvent>(_onAddExpense);
    on<UpdateExpenseEvent>(_onUpdateExpense);
    on<DeleteExpenseEvent>(_onDeleteExpense);
  }

  Future<void> _onLoadExpenses(
    LoadExpensesEvent event,
    Emitter<ExpensesState> emit,
  ) async {
    emit(const ExpensesLoading());
    try {
      final allExpenses = await getExpenses();

      final now = DateTime.now();
      final totalThisMonth = allExpenses
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .fold<double>(0.0, (sum, e) => sum + e.amount);

      var filtered = List<ExpenseEntity>.from(allExpenses);

      if (event.searchQuery.isNotEmpty) {
        final q = event.searchQuery.toLowerCase();
        filtered = filtered
            .where((e) =>
                e.title.toLowerCase().contains(q) ||
                (e.notes != null && e.notes!.toLowerCase().contains(q)) ||
                e.paidBy.toLowerCase().contains(q))
            .toList();
      }

      if (event.filterCategories.isNotEmpty) {
        filtered = filtered
            .where((e) =>
                event.filterCategories.contains(e.category.label) ||
                event.filterCategories.contains(e.category.name))
            .toList();
      }

      final totalExpenses = filtered.fold<double>(
        0.0,
        (sum, e) => sum + e.amount,
      );

      final totalPages = filtered.isEmpty
          ? 1
          : (filtered.length / AppConstants.itemsPerPage).ceil();

      final start = (event.page - 1) * AppConstants.itemsPerPage;
      final end = (start + AppConstants.itemsPerPage)
          .clamp(0, filtered.length)
          .toInt();
      final paginated = start < filtered.length
          ? filtered.sublist(start, end)
          : <ExpenseEntity>[];

      emit(
        ExpensesLoaded(
          expenses: paginated,
          totalExpenses: totalExpenses,
          totalThisMonth: totalThisMonth,
          currentPage: event.page,
          totalPages: totalPages,
          searchQuery: event.searchQuery,
          filterCategories: event.filterCategories,
        ),
      );
    } catch (e) {
      emit(ExpensesError(message: 'Failed to load expenses: $e'));
    }
  }

  Future<void> _onAddExpense(
    AddExpenseEvent event,
    Emitter<ExpensesState> emit,
  ) async {
    try {
      await addExpense(event.expense);
      final currentQuery = state is ExpensesLoaded
          ? (state as ExpensesLoaded).searchQuery
          : '';
      final currentCats = state is ExpensesLoaded
          ? (state as ExpensesLoaded).filterCategories
          : <String>[];
      add(LoadExpensesEvent(
        page: 1,
        searchQuery: currentQuery,
        filterCategories: currentCats,
      ));
    } catch (e) {
      emit(ExpensesError(message: 'Failed to add expense: $e'));
    }
  }

  Future<void> _onUpdateExpense(
    UpdateExpenseEvent event,
    Emitter<ExpensesState> emit,
  ) async {
    try {
      await updateExpense(event.expense);
      final currentPage = state is ExpensesLoaded
          ? (state as ExpensesLoaded).currentPage
          : 1;
      final currentQuery = state is ExpensesLoaded
          ? (state as ExpensesLoaded).searchQuery
          : '';
      final currentCats = state is ExpensesLoaded
          ? (state as ExpensesLoaded).filterCategories
          : <String>[];
      add(LoadExpensesEvent(
        page: currentPage,
        searchQuery: currentQuery,
        filterCategories: currentCats,
      ));
    } catch (e) {
      emit(ExpensesError(message: 'Failed to update expense: $e'));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpenseEvent event,
    Emitter<ExpensesState> emit,
  ) async {
    try {
      await deleteExpense(event.expenseId);
      final currentPage = state is ExpensesLoaded
          ? (state as ExpensesLoaded).currentPage
          : 1;
      final currentQuery = state is ExpensesLoaded
          ? (state as ExpensesLoaded).searchQuery
          : '';
      final currentCats = state is ExpensesLoaded
          ? (state as ExpensesLoaded).filterCategories
          : <String>[];
      add(LoadExpensesEvent(
        page: currentPage,
        searchQuery: currentQuery,
        filterCategories: currentCats,
      ));
    } catch (e) {
      emit(ExpensesError(message: 'Failed to delete expense: $e'));
    }
  }
}
