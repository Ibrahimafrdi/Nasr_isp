import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/reports/domain/entities/monthly_financial_summary.dart';
import 'package:nasr_isp/features/reports/domain/usecases/get_available_report_months.dart';
import 'package:nasr_isp/features/reports/domain/usecases/get_monthly_financial_summary.dart';

/// Sentinel month key selecting the all-time aggregate view rather than a
/// single calendar month. Safe against collision since real month keys are
/// always `YYYY-MM`.
const String kAllTimeReportKey = 'ALL';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when the Reports page is opened (or refreshed).
/// Fetches available months and loads the most recent month's summary.
class LoadReportsEvent extends ReportsEvent {
  const LoadReportsEvent();
}

/// Triggered when the user selects a different month (or [kAllTimeReportKey])
/// in the dropdown.
class SelectReportMonthEvent extends ReportsEvent {
  final String monthKey;

  const SelectReportMonthEvent(this.monthKey);

  @override
  List<Object?> get props => [monthKey];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

/// Months are available, and a summary for [selectedMonthKey] is loaded.
/// [selectedMonthKey] is either a `YYYY-MM` key or [kAllTimeReportKey].
class ReportsLoaded extends ReportsState {
  /// All available months, ascending (oldest first). Never includes
  /// [kAllTimeReportKey] itself — that's added only in the UI's dropdown.
  final List<String> availableMonths;

  /// The currently selected `YYYY-MM` key, or [kAllTimeReportKey].
  final String selectedMonthKey;

  /// Financial summary for [selectedMonthKey] — a single month's figures,
  /// or the summed total across every available month when
  /// [selectedMonthKey] is [kAllTimeReportKey].
  final MonthlyFinancialSummary summary;

  /// Financial summary for the month immediately before [selectedMonthKey],
  /// used only for the month-over-month delta chip. Always null for the
  /// all-time view (a delta against "the month before all time" is
  /// meaningless), for the earliest available month, or if that earlier
  /// month's data couldn't be loaded.
  final MonthlyFinancialSummary? previousSummary;

  const ReportsLoaded({
    required this.availableMonths,
    required this.selectedMonthKey,
    required this.summary,
    this.previousSummary,
  });

  @override
  List<Object?> get props => [
    availableMonths,
    selectedMonthKey,
    summary,
    previousSummary,
  ];
}

/// Indicates that a month-change summary fetch is in progress while the
/// existing months list is still available.
class ReportsSummaryLoading extends ReportsState {
  final List<String> availableMonths;
  final String selectedMonthKey;

  const ReportsSummaryLoading({
    required this.availableMonths,
    required this.selectedMonthKey,
  });

  @override
  List<Object?> get props => [availableMonths, selectedMonthKey];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final GetMonthlyFinancialSummary getMonthlyFinancialSummary;
  final GetAvailableReportMonths getAvailableReportMonths;

  ReportsBloc({
    required this.getMonthlyFinancialSummary,
    required this.getAvailableReportMonths,
  }) : super(const ReportsInitial()) {
    on<LoadReportsEvent>(_onLoad);
    on<SelectReportMonthEvent>(_onSelectMonth);
  }

  Future<void> _onLoad(
    LoadReportsEvent event,
    Emitter<ReportsState> emit,
  ) async {
    emit(const ReportsLoading());
    try {
      final months = await getAvailableReportMonths();
      if (months.isEmpty) {
        emit(const ReportsError(message: 'No data found.'));
        return;
      }
      // Default to the most recent single month (not All-Time) — least
      // surprising thing to land on when opening the page.
      final selectedKey = months.last;
      final summary = await getMonthlyFinancialSummary(
        _monthKeyToDate(selectedKey),
      );
      final previousSummary = await _tryLoadPreviousSummary(
        selectedKey,
        months,
      );
      emit(
        ReportsLoaded(
          availableMonths: months,
          selectedMonthKey: selectedKey,
          summary: summary,
          previousSummary: previousSummary,
        ),
      );
    } catch (e) {
      emit(ReportsError(message: 'Failed to load reports: $e'));
    }
  }

  Future<void> _onSelectMonth(
    SelectReportMonthEvent event,
    Emitter<ReportsState> emit,
  ) async {
    final current = state;
    final List<String> months;
    if (current is ReportsLoaded) {
      months = current.availableMonths;
    } else if (current is ReportsSummaryLoading) {
      months = current.availableMonths;
    } else {
      return;
    }

    emit(
      ReportsSummaryLoading(
        availableMonths: months,
        selectedMonthKey: event.monthKey,
      ),
    );
    try {
      final MonthlyFinancialSummary summary;
      if (event.monthKey == kAllTimeReportKey) {
        summary = await _loadAllTimeSummary(months);
      } else {
        summary = await getMonthlyFinancialSummary(
          _monthKeyToDate(event.monthKey),
        );
      }
      // No month-over-month delta for the all-time aggregate.
      final previousSummary = event.monthKey == kAllTimeReportKey
          ? null
          : await _tryLoadPreviousSummary(event.monthKey, months);
      emit(
        ReportsLoaded(
          availableMonths: months,
          selectedMonthKey: event.monthKey,
          summary: summary,
          previousSummary: previousSummary,
        ),
      );
    } catch (e) {
      emit(ReportsError(message: 'Failed to load month: $e'));
    }
  }

  /// Fetches every available month's summary and sums them into one
  /// all-time total. [unpricedCustomerCount] is a live snapshot ("how many
  /// currently-active customers have no resolved package cost right now"),
  /// not something that's meaningful to sum across months, so the aggregate
  /// carries the most recent month's value rather than a total.
  Future<MonthlyFinancialSummary> _loadAllTimeSummary(
    List<String> months,
  ) async {
    final summaries = await Future.wait(
      months.map((key) => getMonthlyFinancialSummary(_monthKeyToDate(key))),
    );

    double subscriptionBilled = 0;
    double subscriptionCollected = 0;
    double installationRevenue = 0;
    double installationCost = 0;
    double totalExpenses = 0;
    double netProfit = 0;
    final expensesByCategory = <ExpenseCategory, double>{};

    for (final s in summaries) {
      subscriptionBilled += s.subscriptionBilled;
      subscriptionCollected += s.subscriptionCollected;
      installationRevenue += s.installationRevenue;
      installationCost += s.installationCost;
      totalExpenses += s.totalExpenses;
      netProfit += s.netProfit;
      s.expensesByCategory.forEach((cat, amount) {
        expensesByCategory[cat] = (expensesByCategory[cat] ?? 0) + amount;
      });
    }

    return MonthlyFinancialSummary(
      monthKey: kAllTimeReportKey,
      subscriptionBilled: subscriptionBilled,
      subscriptionCollected: subscriptionCollected,
      installationRevenue: installationRevenue,
      installationCost: installationCost,
      totalExpenses: totalExpenses,
      expensesByCategory: expensesByCategory,
      netProfit: netProfit,
      unpricedCustomerCount: summaries.isEmpty
          ? 0
          : summaries
                .last
                .unpricedCustomerCount, // most recent month's snapshot
    );
  }

  /// Loads the summary for the month immediately before [monthKey], purely
  /// for the delta chip. Returns null (rather than throwing) when there's no
  /// earlier month in [availableMonths], or if that month's data fails to
  /// load for any reason — the delta chip is a nice-to-have, not something
  /// that should ever block the page from showing the selected month's own
  /// summary.
  Future<MonthlyFinancialSummary?> _tryLoadPreviousSummary(
    String monthKey,
    List<String> availableMonths,
  ) async {
    final prevKey = _previousMonthKey(monthKey);
    if (!availableMonths.contains(prevKey)) return null;
    try {
      return await getMonthlyFinancialSummary(_monthKeyToDate(prevKey));
    } catch (_) {
      return null;
    }
  }

  /// Parses a `YYYY-MM` key into the first day of that month.
  static DateTime _monthKeyToDate(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Returns the `YYYY-MM` key for the month immediately before [key],
  /// rolling over the year boundary (e.g. `'2026-01'` -> `'2025-12'`).
  static String _previousMonthKey(String key) {
    final parts = key.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]) - 1;
    if (month < 1) {
      month = 12;
      year -= 1;
    }
    return '$year-${month.toString().padLeft(2, '0')}';
  }
}
