import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/responsive/responsive_layout.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/expenses/domain/entities/expense_entity.dart';
import 'package:nasr_isp/features/expenses/presentation/bloc/expenses_bloc.dart';
import 'package:nasr_isp/features/expenses/presentation/widgets/expense_card_list.dart';
import 'package:nasr_isp/features/expenses/presentation/widgets/expense_filter_panel.dart';
import 'package:nasr_isp/shared/widgets/app_filter_widgets.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';
import 'package:fl_chart/fl_chart.dart';

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
    context.read<ExpensesBloc>().add(
          const LoadExpensesEvent(searchQuery: '', filterCategories: []),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _categoryFilter = null;
      _dateRangeStart = null;
      _dateRangeEnd = null;
    });
    context.read<ExpensesBloc>().add(
          const LoadExpensesEvent(searchQuery: '', filterCategories: []),
        );
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
    if (picked != null) {
      setState(() {
        _dateRangeStart = picked.start;
        _dateRangeEnd = picked.end;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;
        return BlocBuilder<ExpensesBloc, ExpensesState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Breadcrumb(
                          items: [
                            BreadcrumbItem(
                              label: 'Home',
                              onTap: () => context.go(RoutePaths.dashboard),
                            ),
                            BreadcrumbItem(label: 'Expenses'),
                          ],
                        ),
                      ),
                      if (isAdmin)
                        ElevatedButton.icon(
                          onPressed: () => _showAddOrEditExpenseDialog(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Expense'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (state is ExpensesLoaded) ...[
                    ExpenseFilterPanel(
                      searchController: _searchController,
                      categoryFilter: _categoryFilter,
                      hasDateRange: _dateRangeStart != null && _dateRangeEnd != null,
                      dateRangeStart: _dateRangeStart,
                      dateRangeEnd: _dateRangeEnd,
                      activeFilterCount: _activeFilterCount,
                      onSearchChanged: (val) {
                        setState(() => _searchQuery = val);
                        context.read<ExpensesBloc>().add(
                              LoadExpensesEvent(
                                searchQuery: val,
                                filterCategories:
                                    _categoryFilter != null ? [_categoryFilter!] : [],
                              ),
                            );
                      },
                      onPickDateRange: _pickDateRange,
                      onClearDateRange: () => setState(() {
                        _dateRangeStart = null;
                        _dateRangeEnd = null;
                      }),
                      onCategoryFilterChanged: (val) {
                        setState(() => _categoryFilter = val);
                        context.read<ExpensesBloc>().add(
                              LoadExpensesEvent(
                                searchQuery: _searchQuery,
                                filterCategories: val != null ? [val] : [],
                              ),
                            );
                      },
                      onClearFilters: _clearFilters,
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 800;
                        return isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildExpenseSummaryCards(
                                      state.totalExpenses,
                                      state.totalThisMonth,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 2,
                                    child: _buildExpensePieChart(
                                      state.expenses,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildExpenseSummaryCards(
                                    state.totalExpenses,
                                    state.totalThisMonth,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildExpensePieChart(state.expenses),
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 32),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: AppTheme.lightGray.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Expense Registry',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            state.expenses.isEmpty
                                ? const EmptyStateWidget(
                                    icon: Icons.receipt_long,
                                    title: 'No expenses recorded',
                                  )
                                : ResponsiveLayout(
                                    mobile: ExpenseCardList(
                                      expenses: state.expenses,
                                      isAdmin: isAdmin,
                                      onEdit: (expense) =>
                                          _showAddOrEditExpenseDialog(context,
                                              expense: expense),
                                      onDelete: (expense) =>
                                          _confirmDeleteExpense(context, expense),
                                    ),
                                    desktop: _buildExpensesTable(
                                      state.expenses,
                                      isAdmin,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    if (state.totalPages > 1) ...[
                      const SizedBox(height: 24),
                      PaginationBar(
                        currentPage: state.currentPage,
                        totalPages: state.totalPages,
                        onPageChanged: (page) {
                          context.read<ExpensesBloc>().add(
                                LoadExpensesEvent(
                                  page: page,
                                  searchQuery: _searchQuery,
                                  filterCategories: _categoryFilter != null
                                      ? [_categoryFilter!]
                                      : [],
                                ),
                              );
                        },
                      ),
                    ],
                  ] else if (state is ExpensesLoading)
                    const LoadingWidget(
                      message: 'Loading business expenses...',
                    )
                  else if (state is ExpensesError)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: const TextStyle(color: AppTheme.errorColor),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ExpensesBloc>().add(
                                    const LoadExpensesEvent(),
                                  );
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExpenseSummaryCards(double totalFiltered, double totalThisMonth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DashboardCard(
                label: 'Total This Month',
                value: DateTimeUtils.formatCurrency(totalThisMonth),
                icon: Icons.calendar_month,
                backgroundColor: AppTheme.errorColor.withValues(alpha: 0.05),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardCard(
                label: 'Filtered Total Spend',
                value: DateTimeUtils.formatCurrency(totalFiltered),
                icon: Icons.account_balance_wallet,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.05),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpensePieChart(List<ExpenseEntity> expenses) {
    final Map<ExpenseCategory, double> totals = {};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    final double sum = totals.values.fold(0.0, (s, v) => s + v);
    final colors = {
      ExpenseCategory.fuel: Colors.amber,
      ExpenseCategory.equipment: Colors.teal,
      ExpenseCategory.salary: Colors.green,
      ExpenseCategory.maintenance: Colors.purple,
      ExpenseCategory.rent: Colors.red,
      ExpenseCategory.internet: Colors.blue,
      ExpenseCategory.electricity: Colors.orange,
      ExpenseCategory.other: Colors.grey,
    };

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.lightGray.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cost Breakdown by Category',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: sum == 0
                  ? const Center(child: Text('No expense data'))
                  : PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 28,
                        sections: totals.entries.map((entry) {
                          final share = (entry.value / sum) * 100;
                          return PieChartSectionData(
                            value: entry.value,
                            title: share >= 5 ? '${share.toStringAsFixed(0)}%' : '',
                            color: colors[entry.key] ?? Colors.grey,
                            radius: 28,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Column(
              children: totals.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors[entry.key] ?? Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key.label,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        DateTimeUtils.formatCurrency(entry.value),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesTable(List<ExpenseEntity> expenses, bool isAdmin) {
    return DataTableWrapper(
      columns: const [
        DataColumn(label: Text('Title')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Amount')),
        DataColumn(label: Text('Paid By')),
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Actions')),
      ],
      rows: expenses.map((e) {
        return DataRow(
          cells: [
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (e.notes != null && e.notes!.isNotEmpty)
                    Text(
                      e.notes!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.mediumGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            DataCell(
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  e.category.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataCell(
              Text(
                DateTimeUtils.formatCurrency(e.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
            DataCell(Text(e.paidBy)),
            DataCell(Text(DateTimeUtils.formatDate(e.date))),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAdmin) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Expense',
                      color: AppTheme.primaryColor,
                      onPressed: () =>
                          _showAddOrEditExpenseDialog(context, expense: e),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Delete Expense',
                      color: AppTheme.errorColor,
                      onPressed: () => _confirmDeleteExpense(context, e),
                    ),
                  ] else
                    const Text('-'),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }


  void _confirmDeleteExpense(BuildContext context, ExpenseEntity expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete expense "${expense.title}" of PKR ${expense.amount.toStringAsFixed(0)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<ExpensesBloc>()
                  .add(DeleteExpenseEvent(expense.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Expense "${expense.title}" deleted'),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditExpenseDialog(BuildContext context,
      {ExpenseEntity? expense}) {
    final isEditing = expense != null;
    final formKey = GlobalKey<FormState>();
    final titleController =
        TextEditingController(text: isEditing ? expense.title : '');
    final amountController = TextEditingController(
        text: isEditing ? expense.amount.toStringAsFixed(0) : '');
    final paidByController =
        TextEditingController(text: isEditing ? expense.paidBy : 'Admin');
    final notesController =
        TextEditingController(text: isEditing ? expense.notes ?? '' : '');

    ExpenseCategory selectedCategory =
        isEditing ? expense.category : ExpenseCategory.other;
    DateTime selectedDate = isEditing ? expense.date : DateTime.now();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Expense' : 'Record Operating Expense'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 480,
                  child: SingleChildScrollView(
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
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<ExpenseCategory>(
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
                                    setDialogState(
                                        () => selectedCategory = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: amountController,
                                decoration: const InputDecoration(
                                  labelText: 'Amount (PKR)',
                                  prefixText: 'PKR ',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Amount is required';
                                  }
                                  if (double.tryParse(v) == null) {
                                    return 'Enter valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setDialogState(
                                        () => selectedDate = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date',
                                    suffixIcon: Icon(Icons.calendar_today,
                                        size: 18),
                                  ),
                                  child: Text(
                                    DateTimeUtils.formatDate(selectedDate),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: paidByController,
                                decoration: const InputDecoration(
                                  labelText: 'Paid By',
                                  hintText: 'e.g. Admin, Manager',
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Paid By is required'
                                    : null,
                              ),
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
                      : () {
                          if (formKey.currentState!.validate()) {
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

                            if (isEditing) {
                              context.read<ExpensesBloc>().add(
                                    UpdateExpenseEvent(updatedEntity),
                                  );
                            } else {
                              context.read<ExpensesBloc>().add(
                                    AddExpenseEvent(updatedEntity),
                                  );
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
                          }
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
