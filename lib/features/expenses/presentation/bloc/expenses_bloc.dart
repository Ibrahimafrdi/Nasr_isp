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
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;

  const LoadExpensesEvent({
    this.page = 1,
    this.searchQuery = '',
    this.filterCategories = const [],
    this.dateRangeStart,
    this.dateRangeEnd,
  });

  @override
  List<Object?> get props =>
      [page, searchQuery, filterCategories, dateRangeStart, dateRangeEnd];
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
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;

  const ExpensesLoaded({
    required this.expenses,
    required this.totalExpenses,
    required this.totalThisMonth,
    required this.currentPage,
    required this.totalPages,
    this.searchQuery = '',
    this.filterCategories = const [],
    this.dateRangeStart,
    this.dateRangeEnd,
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
        dateRangeStart,
        dateRangeEnd,
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
            .where((e) => event.filterCategories.contains(e.category.label))
            .toList();
      }

      if (event.dateRangeStart != null && event.dateRangeEnd != null) {
        final rangeStart = DateTime(
          event.dateRangeStart!.year,
          event.dateRangeStart!.month,
          event.dateRangeStart!.day,
        );
        // Exclusive upper bound one day past the end date, so the whole
        // end day is included regardless of any time-of-day component.
        final rangeEnd = DateTime(
          event.dateRangeEnd!.year,
          event.dateRangeEnd!.month,
          event.dateRangeEnd!.day,
        ).add(const Duration(days: 1));
        filtered = filtered
            .where((e) =>
                !e.date.isBefore(rangeStart) && e.date.isBefore(rangeEnd))
            .toList();
      }

      final totalExpenses = filtered.fold<double>(
        0.0,
        (sum, e) => sum + e.amount,
      );

      final totalPages = filtered.isEmpty
          ? 1
          : (filtered.length / AppConstants.itemsPerPage).ceil();

      // Clamp back into range if the requested page no longer exists (e.g.
      // deleting the last item on the last page shrinks totalPages below
      // the page the UI was still showing).
      final effectivePage = event.page.clamp(1, totalPages);

      final start = (effectivePage - 1) * AppConstants.itemsPerPage;
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
          currentPage: effectivePage,
          totalPages: totalPages,
          searchQuery: event.searchQuery,
          filterCategories: event.filterCategories,
          dateRangeStart: event.dateRangeStart,
          dateRangeEnd: event.dateRangeEnd,
        ),
      );
    } catch (e) {
      emit(ExpensesError(message: 'Failed to load expenses: $e'));
    }
  }

  /// Re-dispatches a load using whatever filters/page are currently on
  /// screen, so an add/update/delete doesn't reset the user's filters.
  void _reloadWithCurrentFilters({int? page}) {
    final current = state is ExpensesLoaded ? state as ExpensesLoaded : null;
    add(LoadExpensesEvent(
      page: page ?? current?.currentPage ?? 1,
      searchQuery: current?.searchQuery ?? '',
      filterCategories: current?.filterCategories ?? const [],
      dateRangeStart: current?.dateRangeStart,
      dateRangeEnd: current?.dateRangeEnd,
    ));
  }

  Future<void> _onAddExpense(
    AddExpenseEvent event,
    Emitter<ExpensesState> emit,
  ) async {
    try {
      await addExpense(event.expense);
      _reloadWithCurrentFilters(page: 1);
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
      _reloadWithCurrentFilters();
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
      _reloadWithCurrentFilters();
    } catch (e) {
      emit(ExpensesError(message: 'Failed to delete expense: $e'));
    }
  }
}
