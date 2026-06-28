import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/responsive/responsive_layout.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/widgets/app_filter_widgets.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _statusFilter;
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

          // Status chips — fixed to spec values
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppStatusChipGroup(
                options: const ['paid', 'unpaid', 'partial'],
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
                    // Stats cards — admin only
                    if (authState.user.role == 'admin') ...[
                      _buildStatsCards(state),
                      const SizedBox(height: 24),
                    ],

                    // Filter panel
                    _buildFilterPanel(),
                    const SizedBox(height: 24),

                    // Payments list
                    state.payments.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.receipt_long,
                            title: 'No Payments In Selection',
                            subtitle:
                                'Modify filters or search term to discover records.',
                          )
                        : ResponsiveLayout(
                            mobile: _buildPaymentCards(
                              state.payments,
                              authState.user.role == 'admin',
                            ),
                            desktop: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: AppTheme.lightGray.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: _buildPaymentsTable(
                                  state.payments,
                                  authState.user.role == 'admin',
                                ),
                              ),
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

  // ── Stats cards ──────────────────────────────────────────────────────────
  Widget _buildStatsCards(PaymentsLoaded state) {
    final cards = [
      DashboardCard(
        label: 'Current Billing Target',
        value: DateTimeUtils.formatCurrency(state.totalAmount),
        icon: Icons.monetization_on,
      ),
      DashboardCard(
        label: 'Collections Realized',
        value: DateTimeUtils.formatCurrency(state.collectedAmount),
        icon: Icons.check_circle_outline,
        backgroundColor: AppTheme.successColor.withValues(alpha: 0.05),
      ),
      DashboardCard(
        label: 'Total Outstanding Dues',
        value: DateTimeUtils.formatCurrency(
          state.totalAmount - state.collectedAmount,
        ),
        icon: Icons.pending_actions,
        backgroundColor: AppTheme.errorColor.withValues(alpha: 0.05),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: cards[1]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[2]),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
            const SizedBox(width: 16),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  // ── Desktop: Payments table ───────────────────────────────────────────────
  Widget _buildPaymentsTable(List<PaymentModel> payments, bool isAdmin) {
    return DataTableWrapper(
      columns: [
        const DataColumn(label: Text('Customer Account')),
        if (isAdmin) ...[
          const DataColumn(label: Text('Plan Price')),
          const DataColumn(label: Text('Amount Collected')),
          const DataColumn(label: Text('Remaining Dues')),
        ],
        const DataColumn(label: Text('Due Date')),
        const DataColumn(label: Text('Status')),
        const DataColumn(label: Text('Method')),
        if (isAdmin) const DataColumn(label: Text('Action')),
      ],
      rows: payments.map((payment) {
        final isPaid = payment.status == 'paid';
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
            if (isAdmin) ...[
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
            ],
            DataCell(
              Text(
                payment.dueDate != null
                    ? DateTimeUtils.formatDate(payment.dueDate!)
                    : 'N/A',
              ),
            ),
            DataCell(PaymentStatusBadge(status: payment.status)),
            DataCell(Text(payment.method ?? 'N/A')),
            if (isAdmin)
              DataCell(
                IconButton(
                  icon: const Icon(Icons.payment),
                  tooltip: isPaid ? 'Dues Settled' : 'Record Receipt',
                  color: isPaid ? AppTheme.mediumGray : AppTheme.primaryColor,
                  onPressed: isPaid
                      ? null
                      : () => _showRecordPaymentDialog(context, payment),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }

  // ── Mobile: Payment cards ─────────────────────────────────────────────────
  Widget _buildPaymentCards(List<PaymentModel> payments, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: payments.map((payment) {
        final isPaid = payment.status == 'paid';
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
              // Customer name + status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      payment.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  PaymentStatusBadge(status: payment.status),
                ],
              ),
              const SizedBox(height: 10),

              // Info chips
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  if (isAdmin) ...[
                    _infoChip(
                      Icons.monetization_on,
                      DateTimeUtils.formatCurrency(payment.amount),
                    ),
                    _infoChip(
                      Icons.check_circle,
                      'Paid: ${DateTimeUtils.formatCurrency(payment.paidAmount)}',
                    ),
                    _infoChip(
                      Icons.warning_amber,
                      'Due: ${DateTimeUtils.formatCurrency(payment.remainingAmount)}',
                      color: payment.remainingAmount > 0
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                    ),
                  ],
                  if (payment.dueDate != null)
                    _infoChip(
                      Icons.calendar_today,
                      DateTimeUtils.formatDate(payment.dueDate!),
                    ),
                  _infoChip(Icons.credit_card, payment.method ?? 'N/A'),
                ],
              ),

              if (isAdmin && !isPaid) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text(
                      'Record Payment',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _showRecordPaymentDialog(context, payment),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Info chip ─────────────────────────────────────────────────────────────
  Widget _infoChip(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color ?? AppTheme.mediumGray),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color ?? AppTheme.mediumGray,
            fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ── Record payment dialog ─────────────────────────────────────────────────
  void _showRecordPaymentDialog(BuildContext context, PaymentModel payment) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: payment.remainingAmount.toString(),
    );
    String selectedMethod = 'cash';
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
                  child: SingleChildScrollView(
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
                          'Outstanding Balance: ${DateTimeUtils.formatCurrency(payment.remainingAmount)}',
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
                            if (v == null || v.isEmpty) {
                              return 'Please enter an amount';
                            }
                            final val = double.tryParse(v);
                            if (val == null || val <= 0) {
                              return 'Please enter a valid positive number';
                            }
                            if (val > payment.remainingAmount) {
                              return 'Amount cannot exceed outstanding balance';
                            }
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
                              value: 'cash',
                              child: Text('Cash Collection'),
                            ),
                            DropdownMenuItem(
                              value: 'bankTransfer',
                              child: Text('Direct Bank Transfer'),
                            ),
                            DropdownMenuItem(
                              value: 'easypaisa',
                              child: Text('EasyPaisa Mobile Wallet'),
                            ),
                            DropdownMenuItem(
                              value: 'jazzcash',
                              child: Text('JazzCash Mobile Wallet'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => selectedMethod = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText:
                                'Collection Reference / Notes (Optional)',
                            hintText: 'e.g. cheque number, transaction ID',
                          ),
                          onChanged: (val) => notes = val,
                        ),
                      ],
                    ),
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
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Payment of PKR ${amountController.text} logged via $selectedMethod!',
                                ),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                            final newPaid = payment.paidAmount + double.parse(amountController.text);
                            final updatedPayment = payment.copyWith(
                              paidAmount: newPaid,
                              status: newPaid >= payment.amount ? 'paid' : 'partial',
                              completedDate: DateTime.now(),
                              method: selectedMethod,
                              notes: notes.isNotEmpty ? notes : null,
                            );
                            context.read<PaymentsBloc>().add(
                              UpdatePaymentEvent(updatedPayment),
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
