import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/expenses/presentation/bloc/expenses_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({Key? key}) : super(key: key);

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  @override
  void initState() {
    super.initState();
    context.read<ExpensesBloc>().add(const LoadExpensesEvent());
  }

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
                child: Container(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(labelText: 'Expense Title / Description'),
                        validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: amountController,
                              decoration: const InputDecoration(labelText: 'Amount (PKR)', prefixText: 'PKR '),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Amount is required';
                                if (double.tryParse(v) == null) return 'Enter a number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<ExpenseCategory>(
                              value: selectedCategory,
                              decoration: const InputDecoration(labelText: 'Category'),
                              items: ExpenseCategory.values.map((cat) {
                                return DropdownMenuItem(value: cat, child: Text(cat.label));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => selectedCategory = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(labelText: 'Audit Memo / Notes (Optional)'),
                        maxLines: 2,
                      ),
                    ],
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
                            await Future.delayed(const Duration(milliseconds: 800));
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Expense "${descController.text}" logged successfully!'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                            context.read<ExpensesBloc>().add(const LoadExpensesEvent());
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Breadcrumb(
                        items: [
                          BreadcrumbItem(
                            label: 'Home',
                            onTap: () => context.go(RoutePaths.dashboard),
                          ),
                          BreadcrumbItem(label: 'Expenses'),
                        ],
                      ),
                      if (authState.user.role.isAdmin)
                        ElevatedButton.icon(
                          onPressed: () => _showAddExpenseDialog(context),
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Add Expense'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (state is ExpensesLoaded) ...[
                    // Expense Summary Row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 800;
                        return isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: _buildExpenseSummaryCards(state.totalExpenses)),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 2, child: _buildExpensePieChart(state.expenses)),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildExpenseSummaryCards(state.totalExpenses),
                                  const SizedBox(height: 24),
                                  _buildExpensePieChart(state.expenses),
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Expenses Table
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Expense Registry',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildExpensesTable(state.expenses),
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
                                LoadExpensesEvent(page: page),
                              );
                        },
                      ),
                    ],
                  ] else if (state is ExpensesLoading)
                    const LoadingWidget(message: 'Loading business cost logs...'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExpenseSummaryCards(double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardCard(
          label: 'Total Expenses (Current Cycle)',
          value: DateTimeUtils.formatCurrency(total),
          icon: Icons.trending_up,
          backgroundColor: AppTheme.errorColor.withOpacity(0.04),
        ),
        const SizedBox(height: 16),
        Row(
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
        ),
      ],
    );
  }

  Widget _buildExpensePieChart(List<ExpenseModel> expenses) {
    // Group and sum categories
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
        side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cost Breakdown by Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
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
                          Text(entry.key.label, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      Text(
                        DateTimeUtils.formatCurrency(entry.value),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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

  Widget _buildExpensesTable(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) {
      return const EmptyStateWidget(icon: Icons.receipt, title: 'No expenses recorded');
    }

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
            DataCell(Text(e.description, style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  e.category.label,
                  style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataCell(Text(DateTimeUtils.formatCurrency(e.amount), style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(DateTimeUtils.formatDate(e.date))),
            DataCell(
              IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                tooltip: 'Notes: ${e.notes ?? 'None'}',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Memo: ${e.notes ?? "No memo recorded."}')),
                  );
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
