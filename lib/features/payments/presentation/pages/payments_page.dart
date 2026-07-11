import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/responsive/responsive_layout.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:nasr_isp/features/payments/presentation/widgets/payment_card_list.dart';
import 'package:nasr_isp/features/payments/presentation/widgets/payment_stats_cards.dart';
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
                // In AppStatusChipGroup onChanged:
                onChanged: (val) {
                  setState(() => _statusFilter = val);
                  context.read<PaymentsBloc>().add(
                    LoadPaymentsEvent(
                      filterStatuses: val != null ? [val] : null, // null not []
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
                            BreadcrumbItem(label: 'Payments'),
                          ],
                        ),
                      ),
                      if (authState.user.role == 'admin')
                        ElevatedButton.icon(
                          onPressed: () => _showAddPaymentDialog(context),
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text('Add Payment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (state is PaymentsLoaded) ...[
                    // Stats cards — admin only
                    if (authState.user.role == 'admin') ...[
                      PaymentStatsCards(
                        totalAmount: state.totalAmount,
                        collectedAmount: state.collectedAmount,
                      ),
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
                            mobile: PaymentCardList(
                              payments: state.payments,
                              isAdmin: authState.user.role == 'admin',
                              onRecordPayment: (p) => _showRecordPaymentDialog(context, p),
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

                    if (state.totalPages > 1 || state.hasMore) ...[
                      const SizedBox(height: 24),
                      PaginationBar(
                        currentPage: state.currentPage,
                        totalPages: state.totalPages,
                        filterStatuses: _statusFilter != null
                            ? [_statusFilter!]
                            : null,
                        onPageChanged: (page) {
                          context.read<PaymentsBloc>().add(
                            LoadPaymentsEvent(
                              page: page,
                              searchQuery: _searchQuery,
                              filterStatuses: _statusFilter != null
                                  ? [_statusFilter!]
                                  : [],
                              dateRangeStart: _dateRangeStart,
                              dateRangeEnd: _dateRangeEnd,
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

  // ── Stats cards — extracted → PaymentStatsCards widget ──────────────────────
  // ── Mobile cards — extracted → PaymentCardList widget ───────────────────────
  // ── Info chip  — extracted → shared InfoChip widget ──────────────────────────

  // ── Desktop: Payments table ───────────────────────────────────────────────
  Widget _buildPaymentsTable(List<PaymentModel> payments, bool isAdmin) {
    return DataTableWrapper(
      columns: [
        const DataColumn(label: Text('Customer Account')),
        const DataColumn(label: Text('Billing Month')),
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
            DataCell(Text(payment.billingMonth ?? '—')),
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

  // ── Add payment dialog ────────────────────────────────────────────────────
  void _showAddPaymentDialog(BuildContext context) {
    context.read<CustomersBloc>().add(const LoadCustomersEvent());
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    String selectedMethod = 'cash';
    String notes = '';
    DateTime paymentDate = DateTime.now();
    bool isSubmitting = false;
    List<CustomerModel> customers = [];

    // Get customers who have partial payments
    final paymentsState = context.read<PaymentsBloc>().state;
    final partialCustomerIds = paymentsState is PaymentsLoaded
        ? paymentsState.payments
              .where((p) => p.status == 'partial')
              .map((p) => p.customerId)
              .toSet()
        : <String>{};

    CustomerModel? selectedCustomer;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BlocListener<CustomersBloc, CustomersState>(
              listener: (context, state) {
                if (state is CustomersLoaded) {
                  final allCustomers = state.customers;

                  final now = DateTime.now();
                  customers = allCustomers.where((c) {
                    // Include if they have an outstanding partial payment
                    if (partialCustomerIds.contains(c.id)) return true;

                    // Include if their nextDueDate is today or past
                    if (c.nextDueDate == null) return true;
                    return c.nextDueDate!.isBefore(now) ||
                        c.nextDueDate!.difference(now).inDays <= 3;
                  }).toList();
                  setDialogState(() {});
                }
              },
              child: AlertDialog(
                title: const Text('Add Payment'),
                content: Form(
                  key: formKey,
                  child: SizedBox(
                    width: 450,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<CustomerModel>(
                            value: selectedCustomer,
                            decoration: const InputDecoration(
                              labelText: 'Select Customer',
                            ),
                            items: customers.map((c) {
                              final isPartial = partialCustomerIds.contains(
                                c.id,
                              );
                              return DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${c.name} — ${c.id.toUpperCase()}',
                                      ),
                                    ),
                                    if (isPartial)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'Partial',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (c) {
                              if (c != null) {
                                setDialogState(() {
                                  selectedCustomer = c;

                                  // Check if they have a partial payment — prefill remaining amount
                                  final partialPayment =
                                      paymentsState is PaymentsLoaded
                                      ? paymentsState.payments
                                            .where(
                                              (p) =>
                                                  p.customerId == c.id &&
                                                  p.status == 'partial',
                                            )
                                            .firstOrNull
                                      : null;

                                  if (partialPayment != null) {
                                    amountController.text = partialPayment
                                        .remainingAmount
                                        .toString();
                                  } else {
                                    amountController.text = c.monthlyBill
                                        .toString();
                                  }
                                });
                              }
                            },
                            validator: (v) =>
                                v == null ? 'Please select a customer' : null,
                          ),
                          if (customers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'No customers are currently due for payment.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: amountController,
                            decoration: InputDecoration(
                              labelText: 'Amount Received (PKR)',
                              hintText:
                                  'Full bill: PKR ${selectedCustomer?.monthlyBill ?? ''}',
                              prefixText: 'PKR ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please enter amount';
                              }
                              if (double.tryParse(v) == null) {
                                return 'Enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedMethod,
                            decoration: const InputDecoration(
                              labelText: 'Payment Method',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'cash',
                                child: Text('Cash'),
                              ),
                              DropdownMenuItem(
                                value: 'bankTransfer',
                                child: Text('Bank Transfer'),
                              ),
                              DropdownMenuItem(
                                value: 'easypaisa',
                                child: Text('EasyPaisa'),
                              ),
                              DropdownMenuItem(
                                value: 'jazzcash',
                                child: Text('JazzCash'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedMethod = val);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.calendar_today,
                              color: AppColors.primaryBlue,
                            ),
                            title: const Text(
                              'Payment Date',
                              style: TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              DateTimeUtils.formatDate(paymentDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: paymentDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setDialogState(() => paymentDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
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
                              setDialogState(() => isSubmitting = true);

                              final billingMonth =
                                  '${paymentDate.year}-${paymentDate.month.toString().padLeft(2, '0')}';
                              final customer = selectedCustomer!;
                              final fullAmount = customer.monthlyBill
                                  .toDouble();
                              final enteredAmount = double.parse(
                                amountController.text.trim(),
                              );
                              final isPaidInFull = enteredAmount >= fullAmount;
                              final currentBillingMonth = billingMonth;
                              final nextDueDate = DateTime(
                                paymentDate.year,
                                paymentDate.month + 1,
                                paymentDate.day,
                              );

                              final payment = PaymentModel(
                                id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
                                customerId: customer.id,
                                customerName: customer.name,
                                amount: fullAmount,
                                paidAmount: enteredAmount,
                                status: isPaidInFull ? 'paid' : 'partial',
                                dueDate: nextDueDate,
                                completedDate: isPaidInFull
                                    ? paymentDate
                                    : null,
                                method: selectedMethod,
                                notes: notes.isEmpty ? null : notes,
                                billingMonth: currentBillingMonth,
                                createdAt: DateTime.now(),
                                paymentDate: paymentDate,
                              );

                              context.read<PaymentsBloc>().add(
                                CreatePaymentEvent(payment),
                              );

                              // Only update nextDueDate on customer if fully paid
                              if (isPaidInFull) {
                                final updatedCustomer = customer.copyWith(
                                  nextDueDate: nextDueDate,
                                );
                                context.read<CustomersBloc>().add(
                                  UpdateCustomerEvent(updatedCustomer),
                                );
                              }

                              await Future.delayed(
                                const Duration(milliseconds: 800),
                              );
                              if (!ctx.mounted) return;

                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Payment recorded successfully!',
                                  ),
                                  backgroundColor: AppTheme.successColor,
                                ),
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
                    label: Text(isSubmitting ? 'Saving...' : 'Record Payment'),
                  ),
                ],
              ),
            );
          },
        );
      },
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
                            final newPaid =
                                payment.paidAmount +
                                double.parse(amountController.text);
                            final updatedPayment = payment.copyWith(
                              paidAmount: newPaid,
                              status: newPaid >= payment.amount
                                  ? 'paid'
                                  : 'partial',
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
