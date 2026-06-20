import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/widgets/app_filter_widgets.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({Key? key}) : super(key: key);

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _statusFilter; // null == "All"
  DateTime? _dateRangeStart;
  DateTime? _dateRangeEnd;

  // ── Active filter count ─────────────────────────────────────────────────────
  int get _activeFilterCount {
    int count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_statusFilter != null) count++;
    if (_dateRangeStart != null) count++;
    if (_dateRangeEnd != null) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    context.read<PaymentsBloc>().add(const LoadPaymentsEvent());
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
      _statusFilter = null;
      _dateRangeStart = null;
      _dateRangeEnd = null;
    });
    context.read<PaymentsBloc>().add(const LoadPaymentsEvent());
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

    return AppFilterContainer(
      title: 'Search & Filter Payments',
      titleIcon: Icons.payment,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          AppSearchField(
            controller: _searchController,
            hintText: 'Search by customer name...',
            onChanged: (val) {
              setState(() => _searchQuery = val);
              context.read<PaymentsBloc>().add(
                LoadPaymentsEvent(searchQuery: val),
              );
            },
            onClear: () {
              setState(() => _searchQuery = '');
              context.read<PaymentsBloc>().add(const LoadPaymentsEvent());
            },
          ),
          const SizedBox(height: 14),

          // Date range row
          Row(
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
              if (hasDateRange) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear date range',
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () => setState(() {
                    _dateRangeStart = null;
                    _dateRangeEnd = null;
                  }),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Status chips + badge + clear
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppStatusChipGroup(
                options: const ['Completed', 'Pending', 'Failed', 'Partial'],
                selected: _statusFilter,
                onChanged: (val) {
                  setState(() => _statusFilter = val);
                  context.read<PaymentsBloc>().add(
                    LoadPaymentsEvent(
                      filterStatuses: val != null ? [val] : [],
                      searchQuery: _searchQuery,
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
          return const Scaffold(body: Center(child: Text('Not authenticated')));
        }
        return BlocBuilder<PaymentsBloc, PaymentsState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb
                  Breadcrumb(
                    items: [
                      BreadcrumbItem(
                        label: 'Home',
                        onTap: () => context.go(RoutePaths.dashboard),
                      ),
                      BreadcrumbItem(label: 'Payments'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (state is PaymentsLoaded) ...[
                    // Financial stats cards (unchanged)
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            label: 'Current Billing Target',
                            value: DateTimeUtils.formatCurrency(
                              state.totalAmount,
                            ),
                            icon: Icons.monetization_on,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DashboardCard(
                            label: 'Collections Realized',
                            value: DateTimeUtils.formatCurrency(
                              state.collectedAmount,
                            ),
                            icon: Icons.check_circle_outline,
                            backgroundColor: AppTheme.successColor.withOpacity(
                              0.05,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DashboardCard(
                            label: 'Total Outstanding Dues',
                            value: DateTimeUtils.formatCurrency(
                              state.totalAmount - state.collectedAmount,
                            ),
                            icon: Icons.pending_actions,
                            backgroundColor: AppTheme.errorColor.withOpacity(
                              0.05,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Centralized filter panel
                    _buildFilterPanel(),
                    const SizedBox(height: 24),

                    // Payments table (unchanged)
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: AppTheme.lightGray.withOpacity(0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _buildPaymentsTable(state.payments),
                      ),
                    ),

                    if (state.totalPages > 1) ...[
                      const SizedBox(height: 24),
                      PaginationBar(
                        currentPage: state.currentPage,
                        totalPages: state.totalPages,
                        onPageChanged: (page) {
                          context.read<PaymentsBloc>().add(
                            LoadPaymentsEvent(
                              page: page,
                              searchQuery: _searchQuery,
                              filterStatuses: _statusFilter != null
                                  ? [_statusFilter!]
                                  : [],
                            ),
                          );
                        },
                      ),
                    ],
                  ] else if (state is PaymentsLoading)
                    const LoadingWidget(
                      message: 'Loading financial general ledgers...',
                    )
                  else
                    const EmptyStateWidget(
                      icon: Icons.receipt_long,
                      title: 'No Data Available',
                      subtitle: 'Unable to load payment records.',
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Payments table (unchanged) ───────────────────────────────────────────────
  Widget _buildPaymentsTable(List<PaymentModel> payments) {
    if (payments.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long,
        title: 'No Payments In Selection',
        subtitle: 'Modify filters or search term to discover records.',
      );
    }

    return DataTableWrapper(
      columns: const [
        DataColumn(label: Text('Customer Account')),
        DataColumn(label: Text('Plan Price')),
        DataColumn(label: Text('Amount Collected')),
        DataColumn(label: Text('Remaining Dues')),
        DataColumn(label: Text('Due Date')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Method')),
        DataColumn(label: Text('Action')),
      ],
      rows: payments.map((payment) {
        final isCompleted = payment.status == PaymentStatus.completed;
        return DataRow(
          cells: [
            DataCell(
              Text(
                payment.customerName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            DataCell(Text(DateTimeUtils.formatCurrency(payment.amount))),
            DataCell(Text(DateTimeUtils.formatCurrency(payment.paidAmount))),
            DataCell(
              Text(
                DateTimeUtils.formatCurrency(payment.remainingAmount),
                style: TextStyle(
                  color: payment.remainingAmount > 0
                      ? AppTheme.errorColor
                      : AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataCell(Text(DateTimeUtils.formatDate(payment.dueDate))),
            DataCell(PaymentStatusBadge(status: payment.status)),
            DataCell(Text(payment.method ?? 'N/A')),
            DataCell(
              IconButton(
                icon: const Icon(Icons.payment),
                tooltip: isCompleted ? 'Dues Settled' : 'Record Receipt',
                color: isCompleted
                    ? AppTheme.mediumGray
                    : AppTheme.primaryColor,
                onPressed: isCompleted
                    ? null
                    : () => _showRecordPaymentDialog(context, payment),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Record payment dialog (unchanged) ────────────────────────────────────────
  void _showRecordPaymentDialog(BuildContext context, PaymentModel payment) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: payment.remainingAmount.toString(),
    );
    String selectedMethod = 'Bank Transfer';
    String notes = '';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Record Payment: ${payment.customerName}'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Billing Dues: ${DateTimeUtils.formatCurrency(payment.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Outstanding balance: ${DateTimeUtils.formatCurrency(payment.remainingAmount)}',
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Divider(height: 24),
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Payment Amount Received (PKR)',
                          prefixText: 'PKR ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Please enter an amount';
                          final val = double.tryParse(v);
                          if (val == null || val <= 0)
                            return 'Please enter a valid positive number';
                          if (val > payment.remainingAmount)
                            return 'Amount cannot exceed outstanding balance';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Collection Method',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Cash',
                            child: Text('Cash Collection'),
                          ),
                          DropdownMenuItem(
                            value: 'Bank Transfer',
                            child: Text('Direct Bank Transfer'),
                          ),
                          DropdownMenuItem(
                            value: 'EasyPaisa',
                            child: Text('EasyPaisa Mobile Wallet'),
                          ),
                          DropdownMenuItem(
                            value: 'JazzCash',
                            child: Text('JazzCash Mobile Wallet'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => selectedMethod = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Collection Reference / Notes (Optional)',
                          hintText: 'e.g. cheque number, transaction ID',
                        ),
                        onChanged: (val) => notes = val,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isSubmitting = true);
                            await Future.delayed(
                              const Duration(milliseconds: 800),
                            );
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Payment of PKR ${amountController.text} logged via $selectedMethod!',
                                ),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                            context.read<PaymentsBloc>().add(
                              const LoadPaymentsEvent(),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: Text(isSubmitting ? 'Recording...' : 'Record Receipt'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
