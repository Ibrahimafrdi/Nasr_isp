import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
import 'package:nasr_isp/shared/widgets/adaptive_field_row.dart';
import 'package:nasr_isp/shared/widgets/adaptive_form_dialog.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/core/utils/input_formatters.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/expenses/domain/entities/expense_entity.dart';
import 'package:nasr_isp/features/expenses/presentation/bloc/expenses_bloc.dart';
import 'package:nasr_isp/features/expenses/presentation/widgets/expense_card_list.dart';
import 'package:nasr_isp/features/expenses/presentation/widgets/expense_filter_panel.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _categoryFilter; // null == "All"
  DateTime? _dateRangeStart;
  DateTime? _dateRangeEnd;
  Timer? _searchDebounce;

  // Cached last successfully loaded state, so a transient ExpensesLoading
  // or an ExpensesError doesn't blank out or replace an already-visible list.
  ExpensesLoaded? _lastLoaded;

  int get _activeFilterCount {
    int count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_categoryFilter != null) count++;
    if (_dateRangeStart != null) count++;
    if (_dateRangeEnd != null) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _dispatchLoad();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Dispatches a load using the current search/category/date-range filters.
  void _dispatchLoad({int page = 1}) {
    context.read<ExpensesBloc>().add(
      LoadExpensesEvent(
        page: page,
        searchQuery: _searchQuery,
        filterCategories: _categoryFilter != null ? [_categoryFilter!] : [],
        dateRangeStart: _dateRangeStart,
        dateRangeEnd: _dateRangeEnd,
      ),
    );
  }

  void _onSearchChanged(String val) {
    setState(() => _searchQuery = val);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppConstants.debounceDelay, () {
      if (!mounted) return;
      _dispatchLoad();
    });
  }

  void _onCategoryFilterChanged(String? val) {
    _searchDebounce?.cancel();
    setState(() => _categoryFilter = val);
    _dispatchLoad();
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _categoryFilter = null;
      _dateRangeStart = null;
      _dateRangeEnd = null;
    });
    _dispatchLoad();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRangeStart != null && _dateRangeEnd != null
          ? DateTimeRange(start: _dateRangeStart!, end: _dateRangeEnd!)
          : null,
    );
    if (!mounted) return;
    if (picked != null) {
      _searchDebounce?.cancel();
      setState(() {
        _dateRangeStart = picked.start;
        _dateRangeEnd = picked.end;
      });
      _dispatchLoad();
    }
  }

  void _onClearDateRange() {
    _searchDebounce?.cancel();
    setState(() {
      _dateRangeStart = null;
      _dateRangeEnd = null;
    });
    _dispatchLoad();
  }

  static const _accent = Color(0xFF0F766E);
  static const _ink = Color(0xFF14213D);
  static const _muted = Color(0xFF5B6472);
  static const _border = Color(0xFFE3E6EB);
  static const _line = Color(0xFFC9CED6);

  /// Rs 45,000 style.
  String _rs(num amount) {
    final digits = amount.round().toString();
    final withCommas = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return 'Rs $withCommas';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isAdmin =
            authState is AuthAuthenticated && authState.user.isAdmin;
        final currentUserName = authState is AuthAuthenticated
            ? authState.user.name
            : null;
        return BlocConsumer<ExpensesBloc, ExpensesState>(
          listener: (context, state) {
            if (state is ExpensesLoaded) {
              _lastLoaded = state;
            } else if (state is ExpensesError && _lastLoaded != null) {
              // Keep the existing list on screen; just surface the failure.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          },
          builder: (context, rawState) {
            // Prefer the freshly-loaded state; otherwise fall back to the
            // last successfully loaded list rather than blanking the page
            // during a transient reload or a failed add/update/delete.
            final state = rawState is ExpensesLoaded ? rawState : _lastLoaded;
            final loadingOrError = state == null ? rawState : null;

            return SingleChildScrollView(
              padding: Responsive.pagePaddingFor(
                Responsive.deviceTypeOf(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ───────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expenses',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Every rupee spent running the business.',
                              style: TextStyle(fontSize: 14, color: _muted),
                            ),
                          ],
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddOrEditExpenseDialog(
                            context,
                            currentUserName: currentUserName,
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add expense'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (state != null) ...[
                    // ── Summary + breakdown ────────────────────────────────
                    _buildSummary(
                      state.totalThisMonth,
                      state.totalExpenses,
                      state.expenses,
                      state.totalPages > 1,
                    ),
                    const SizedBox(height: 24),

                    // ── Filters ────────────────────────────────────────────
                    ExpenseFilterPanel(
                      searchController: _searchController,
                      categoryFilter: _categoryFilter,
                      hasDateRange:
                          _dateRangeStart != null && _dateRangeEnd != null,
                      dateRangeStart: _dateRangeStart,
                      dateRangeEnd: _dateRangeEnd,
                      activeFilterCount: _activeFilterCount,
                      onSearchChanged: _onSearchChanged,
                      onPickDateRange: _pickDateRange,
                      onClearDateRange: _onClearDateRange,
                      onCategoryFilterChanged: _onCategoryFilterChanged,
                      onClearFilters: _clearFilters,
                    ),
                    const SizedBox(height: 16),

                    // ── List ───────────────────────────────────────────────
                    if (state.expenses.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                        ),
                        child: EmptyStateWidget(
                          icon: Icons.receipt_long,
                          title: _activeFilterCount > 0
                              ? 'No expenses match your filters'
                              : 'No expenses recorded',
                        ),
                      )
                    else
                      ResponsiveSwitcher(
                        mobile: ExpenseCardList(
                          expenses: state.expenses,
                          isAdmin: isAdmin,
                          onEdit: (expense) => _showAddOrEditExpenseDialog(
                            context,
                            expense: expense,
                            currentUserName: currentUserName,
                          ),
                          onDelete: (expense) =>
                              _confirmDeleteExpense(context, expense),
                        ),
                        desktop: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildExpensesTable(
                            state.expenses,
                            isAdmin,
                            currentUserName,
                          ),
                        ),
                      ),
                    if (state.totalPages > 1) ...[
                      const SizedBox(height: 24),
                      PaginationBar(
                        currentPage: state.currentPage,
                        totalPages: state.totalPages,
                        onPageChanged: (page) => _dispatchLoad(page: page),
                      ),
                    ],
                  ] else if (loadingOrError is ExpensesError)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            loadingOrError.message,
                            style: const TextStyle(color: AppTheme.errorColor),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _dispatchLoad,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else
                    const LoadingWidget(
                      message: 'Loading business expenses...',
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Summary: two numbers + where the money goes ────────────────────────────

  Widget _statCard(String label, String value, {String? note}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note, style: const TextStyle(fontSize: 12, color: _muted)),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary(
    double totalThisMonth,
    double totalFiltered,
    List<ExpenseEntity> expenses,
    bool partial,
  ) {
    final stats = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _statCard('Spent this month', _rs(totalThisMonth)),
        const SizedBox(height: 16),
        _statCard(
          'Total in this view',
          _rs(totalFiltered),
          note: _activeFilterCount > 0
              ? 'Matches your filters'
              : 'All expenses',
        ),
      ],
    );
    final breakdown = _buildBreakdown(expenses, partial);

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: stats),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: breakdown),
            ],
          );
        }
        return Column(children: [stats, const SizedBox(height: 16), breakdown]);
      },
    );
  }

  /// Bars sorted largest first. Width is proportional to the biggest category.
  Widget _buildBreakdown(List<ExpenseEntity> expenses, bool partial) {
    final totals = <ExpenseCategory, double>{};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    final sum = totals.values.fold(0.0, (s, v) => s + v);
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = entries.isEmpty ? 0.0 : entries.first.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where the money goes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
          const SizedBox(height: 16),
          if (sum == 0)
            const Text(
              'No expense data.',
              style: TextStyle(fontSize: 14, color: _muted),
            )
          else
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key.label,
                          style: const TextStyle(fontSize: 14, color: _ink),
                        ),
                        Text(
                          '${_rs(entry.value)}  ·  ${(entry.value / sum * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxValue > 0 ? entry.value / maxValue : 0.0,
                        minHeight: 8,
                        backgroundColor: _border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          if (partial && sum > 0)
            const Text(
              'Based on the expenses shown on this page only.',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
        ],
      ),
    );
  }

  // ── Table (fills the full width) ───────────────────────────────────────────

  Widget _headerCell(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: _muted,
    ),
  );

  Widget _tableRow(List<int> flex, List<Widget> cells, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEEF0F3))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flex[i],
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: cells[i],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpensesTable(
    List<ExpenseEntity> expenses,
    bool isAdmin,
    String? currentUserName,
  ) {
    final flex = isAdmin
        ? const [28, 12, 13, 14, 14, 16]
        : const [34, 14, 16, 18, 18];
    final minWidth = isAdmin ? 860.0 : 640.0;

    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth < minWidth ? minWidth : c.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                _tableRow(flex, [
                  _headerCell('Expense'),
                  _headerCell('Category'),
                  _headerCell('Amount'),
                  _headerCell('Paid by'),
                  _headerCell('Date'),
                  if (isAdmin) _headerCell('Actions'),
                ]),
                for (var i = 0; i < expenses.length; i++)
                  _expenseRow(
                    flex,
                    expenses[i],
                    isAdmin,
                    currentUserName,
                    last: i == expenses.length - 1,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _expenseRow(
    List<int> flex,
    ExpenseEntity e,
    bool isAdmin,
    String? currentUserName, {
    required bool last,
  }) {
    return _tableRow(flex, [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            e.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _ink,
            ),
          ),
          if (e.notes != null && e.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                e.notes!,
                style: const TextStyle(fontSize: 12, color: _muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F2F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            e.category.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0B5B55),
            ),
          ),
        ),
      ),
      Text(
        _rs(e.amount),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: _ink,
        ),
      ),
      Text(e.paidBy, style: const TextStyle(fontSize: 14, color: _ink)),
      Text(
        DateTimeUtils.formatDate(e.date),
        style: const TextStyle(fontSize: 14, color: _ink),
      ),
      if (isAdmin)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                foregroundColor: _ink,
                side: const BorderSide(color: _line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              onPressed: () => _showAddOrEditExpenseDialog(
                context,
                expense: e,
                currentUserName: currentUserName,
              ),
              child: const Text('Edit'),
            ),
            PopupMenuButton<String>(
              tooltip: 'More actions',
              icon: const Icon(Icons.more_horiz),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onSelected: (v) {
                if (v == 'delete') _confirmDeleteExpense(context, e);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete expense',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
          ],
        ),
    ], last: last);
  }

  void _confirmDeleteExpense(BuildContext context, ExpenseEntity expense) {
    bool isDeleting = false;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: Text(
                'Are you sure you want to delete expense "${expense.title}" of PKR ${expense.amount.toStringAsFixed(0)}?',
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          final bloc = context.read<ExpensesBloc>();
                          bloc.add(DeleteExpenseEvent(expense.id));

                          final result = await bloc.stream.firstWhere(
                            (s) => s is ExpensesLoaded || s is ExpensesError,
                          );

                          if (!ctx.mounted || !context.mounted) return;

                          if (result is ExpensesError) {
                            setDialogState(() => isDeleting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to delete expense: ${result.message}',
                                ),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Expense "${expense.title}" deleted',
                              ),
                            ),
                          );
                        },
                  child: Text(isDeleting ? 'Deleting...' : 'Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddOrEditExpenseDialog(
    BuildContext context, {
    ExpenseEntity? expense,
    String? currentUserName,
  }) {
    final isEditing = expense != null;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(
      text: isEditing ? expense.title : '',
    );
    final amountController = TextEditingController(
      text: isEditing ? expense.amount.toStringAsFixed(0) : '',
    );
    final paidByController = TextEditingController(
      text: isEditing ? expense.paidBy : (currentUserName ?? 'Admin'),
    );
    final notesController = TextEditingController(
      text: isEditing ? expense.notes ?? '' : '',
    );

    ExpenseCategory selectedCategory = isEditing
        ? expense.category
        : ExpenseCategory.other;
    DateTime selectedDate = isEditing ? expense.date : DateTime.now();
    bool isSaving = false;

    showAppFormDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AdaptiveFormDialog(
              title: isEditing ? 'Edit Expense' : 'Record Operating Expense',
              desktopWidth: 480,
              canClose: !isSaving,
              onClose: () => Navigator.pop(ctx),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Expense Title',
                        hintText: 'e.g., Office Rent June, Fiber Repair',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AdaptiveFieldRow(
                      children: [
                        DropdownButtonFormField<ExpenseCategory>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          items: ExpenseCategory.values
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat.label),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedCategory = val);
                            }
                          },
                        ),
                        TextFormField(
                          controller: amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount (PKR)',
                            prefixText: 'PKR ',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: AppInputFormatters.decimal,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Amount is required';
                            }
                            final parsed = double.tryParse(v);
                            if (parsed == null) {
                              return 'Enter valid number';
                            }
                            if (parsed <= 0) {
                              return 'Amount must be greater than 0';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AdaptiveFieldRow(
                      children: [
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (!context.mounted) return;
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              suffixIcon: Icon(Icons.calendar_today, size: 18),
                            ),
                            child: Text(DateTimeUtils.formatDate(selectedDate)),
                          ),
                        ),
                        TextFormField(
                          controller: paidByController,
                          decoration: const InputDecoration(
                            labelText: 'Paid By',
                            hintText: 'e.g. Admin, Manager',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Paid By is required'
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Remarks (Optional)',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          final updatedEntity = ExpenseEntity(
                            id: isEditing ? expense.id : '',
                            title: titleController.text.trim(),
                            category: selectedCategory,
                            amount: double.parse(amountController.text.trim()),
                            date: selectedDate,
                            paidBy: paidByController.text.trim(),
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                            createdAt: isEditing ? expense.createdAt : null,
                          );

                          final bloc = context.read<ExpensesBloc>();
                          if (isEditing) {
                            bloc.add(UpdateExpenseEvent(updatedEntity));
                          } else {
                            bloc.add(AddExpenseEvent(updatedEntity));
                          }

                          final result = await bloc.stream.firstWhere(
                            (s) => s is ExpensesLoaded || s is ExpensesError,
                          );

                          if (!ctx.mounted || !context.mounted) return;

                          if (result is ExpensesError) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to save: ${result.message}',
                                ),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing
                                    ? 'Expense updated successfully'
                                    : 'Expense recorded successfully',
                              ),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(isEditing ? Icons.save : Icons.check, size: 16),
                  label: Text(isEditing ? 'Save Changes' : 'Record Expense'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
