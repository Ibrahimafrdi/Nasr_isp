import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/responsive/responsive_layout.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/expenses/presentation/bloc/expenses_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';
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

  // ── Active filter count ─────────────────────────────────────────────────────
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

  // ── Clear all filters ───────────────────────────────────────────────────────
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

  // ── Date range picker ───────────────────────────────────────────────────────
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

  // ── Filter panel ────────────────────────────────────────────────────────────
  Widget _buildFilterPanel() {
    final hasDateRange = _dateRangeStart != null && _dateRangeEnd != null;
    final categoryLabels = ExpenseCategory.values.map((c) => c.label).toList();

    return AppFilterContainer(
      title: 'Search & Filter Expenses',
      titleIcon: Icons.receipt_long,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          AppSearchField(
            controller: _searchController,
            hintText: 'Search by description...',
            onChanged: (val) {
              setState(() => _searchQuery = val);
              context.read<ExpensesBloc>().add(
                LoadExpensesEvent(
                  searchQuery: val,
                  filterCategories: _categoryFilter != null
                      ? [_categoryFilter!]
                      : [],
                ),
              );
            },
            onClear: () {
              setState(() => _searchQuery = '');
              context.read<ExpensesBloc>().add(
                LoadExpensesEvent(
                  searchQuery: '',
                  filterCategories: _categoryFilter != null
                      ? [_categoryFilter!]
                      : [],
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Date range row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range_rounded, size: 16),
                label: Text(
                  hasDateRange
                      ? '${DateTimeUtils.formatDate(_dateRangeStart!)}  →  ${DateTimeUtils.formatDate(_dateRangeEnd!)}'
                      : 'Select Date Range',
                  style: const TextStyle(fontSize: 12.5),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
              if (hasDateRange)
                IconButton(
                  tooltip: 'Clear date range',
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () => setState(() {
                    _dateRangeStart = null;
                    _dateRangeEnd = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Category chips + badge + clear
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppStatusChipGroup(
                options: categoryLabels,
                selected: _categoryFilter,
                allLabel: 'All Categories',
                onChanged: (val) {
                  setState(() => _categoryFilter = val);
                  context.read<ExpensesBloc>().add(
                    LoadExpensesEvent(
                      searchQuery: _searchQuery,
                      filterCategories: val != null ? [val] : [],
                    ),
                  );
                },
              ),
              AppFilterBadge(count: _activeFilterCount),
              AppClearFilterButton(
                isVisible: _activeFilterCount > 0,
                onClear: _clearFilters,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: Text('Not authenticated'));
        }
        return BlocBuilder<ExpensesBloc, ExpensesState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with breadcrumb + add button
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
                      if (authState.user.isAdmin)
                        ElevatedButton.icon(
                          onPressed: () => _showAddExpenseDialog(context),
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Add Expense'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (state is ExpensesLoaded) ...[
                    // Centralized filter panel
                    _buildFilterPanel(),
                    const SizedBox(height: 24),

                    // Summary + pie chart (responsive)
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
                                  ),
                                  const SizedBox(height: 24),
                                  _buildExpensePieChart(state.expenses),
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Expenses table / cards — responsive
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            state.expenses.isEmpty
                                ? const EmptyStateWidget(
                                    icon: Icons.receipt,
                                    title: 'No expenses recorded',
                                  )
                                : ResponsiveLayout(
                                    mobile: _buildExpenseCards(state.expenses),
                                    desktop: _buildExpensesTable(state.expenses),
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
                      message: 'Loading business cost logs...',
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Summary cards ────────────────────────────────────────────────────────────
  Widget _buildExpenseSummaryCards(double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardCard(
          label: 'Total Expenses (Current Cycle)',
          value: DateTimeUtils.formatCurrency(total),
          icon: Icons.trending_up,
          backgroundColor: AppTheme.errorColor.withValues(alpha: 0.04),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 400) {
              return Column(
                children: [
                  DashboardCard(
                    label: 'Internet Transit (Upstream)',
                    value: DateTimeUtils.formatCurrency(total * 0.45),
                    subtitle: '45% of total spend',
                  ),
                  const SizedBox(height: 12),
                  DashboardCard(
                    label: 'Salary & Payroll',
                    value: DateTimeUtils.formatCurrency(total * 0.35),
                    subtitle: '35% of total spend',
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    label: 'Internet Transit (Upstream)',
                    value: DateTimeUtils.formatCurrency(total * 0.45),
                    subtitle: '45% of total spend',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DashboardCard(
                    label: 'Salary & Payroll',
                    value: DateTimeUtils.formatCurrency(total * 0.35),
                    subtitle: '35% of total spend',
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ── Pie chart ────────────────────────────────────────────────────────────────
  Widget _buildExpensePieChart(List<ExpenseModel> expenses) {
    final Map<ExpenseCategory, double> totals = {};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    final double sum = totals.values.fold(0.0, (s, v) => s + v);
    final colors = {
      ExpenseCategory.rent: Colors.red,
      ExpenseCategory.electricity: Colors.orange,
      ExpenseCategory.fuel: Colors.amber,
      ExpenseCategory.internetUpstream: Colors.blue,
      ExpenseCategory.salaries: Colors.green,
      ExpenseCategory.repairs: Colors.purple,
      ExpenseCategory.equipment: Colors.teal,
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: sum == 0
                  ? const Center(child: Text('No data'))
                  : PieChart(
                      PieChartData(
                        sectionsSpace: 1,
                        centerSpaceRadius: 30,
                        sections: totals.entries.map((entry) {
                          final share = (entry.value / sum) * 100;
                          return PieChartSectionData(
                            value: entry.value,
                            title: '${share.toStringAsFixed(0)}%',
                            color: colors[entry.key] ?? Colors.grey,
                            radius: 30,
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
                            color: colors[entry.key] ?? Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key.label,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      Text(
                        DateTimeUtils.formatCurrency(entry.value),
                        style: const TextStyle(
                          fontSize: 11,
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

  // ── Desktop: Expenses table ──────────────────────────────────────────────────
  Widget _buildExpensesTable(List<ExpenseModel> expenses) {
    return DataTableWrapper(
      columns: const [
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Amount')),
        DataColumn(label: Text('Log Date')),
        DataColumn(label: Text('Action')),
      ],
      rows: expenses.map((e) {
        return DataRow(
          cells: [
            DataCell(
              Text(
                e.description,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataCell(Text(DateTimeUtils.formatDate(e.date))),
            DataCell(
              IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                tooltip: 'Notes: ${e.notes ?? 'None'}',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Memo: ${e.notes ?? "No memo recorded."}'),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Mobile: Expense cards ──────────────────────────────────────────────────
  Widget _buildExpenseCards(List<ExpenseModel> expenses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: expenses.map((e) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightGray.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description + category chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      e.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      e.category.label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Info row
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _infoChip(
                    Icons.monetization_on,
                    DateTimeUtils.formatCurrency(e.amount),
                  ),
                  _infoChip(Icons.calendar_today, DateTimeUtils.formatDate(e.date)),
                  if (e.notes != null && e.notes!.isNotEmpty)
                    _infoChip(Icons.notes, e.notes!),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.mediumGray),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.mediumGray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Add expense dialog ───────────────────────────────────────────────────────
  void _showAddExpenseDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    ExpenseCategory selectedCategory = ExpenseCategory.rent;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Record Operating Expense'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 450,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: descController,
                          decoration: const InputDecoration(
                            labelText: 'Expense Title / Description',
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Description is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: amountController,
                                decoration: const InputDecoration(
                                  labelText: 'Amount (PKR)',
                                  prefixText: 'PKR ',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Amount is required';
                                  }
                                  if (double.tryParse(v) == null) {
                                    return 'Enter a number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
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
                                    setState(() => selectedCategory = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: notesController,
                          decoration: const InputDecoration(
                            labelText: 'Audit Memo / Notes (Optional)',
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
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isSaving = true);
                            await Future.delayed(
                              const Duration(milliseconds: 800),
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Expense "${descController.text}" logged successfully!',
                                ),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                            context.read<ExpensesBloc>().add(
                              const LoadExpensesEvent(
                                searchQuery: '',
                                filterCategories: [],
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
                      : const Icon(Icons.check, size: 16),
                  label: Text(isSaving ? 'Logging...' : 'Log Expense'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
