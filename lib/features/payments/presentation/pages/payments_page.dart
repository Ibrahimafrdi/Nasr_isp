import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({Key? key}) : super(key: key);

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  late TextEditingController _searchController;
  PaymentStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    context.read<PaymentsBloc>().add(const LoadPaymentsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                child: Container(
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
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter an amount';
                          final val = double.tryParse(value);
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
                            // Reload list
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: Text('Not authenticated')));
        }

        final user = authState.user;

        return BlocBuilder<PaymentsBloc, PaymentsState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    // Financial Stats Cards
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

                    // Advanced Filter Panel
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: AppTheme.lightGray.withOpacity(0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search payments by subscriber name...',
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon:
                                          _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                _searchController.clear();
                                                context
                                                    .read<PaymentsBloc>()
                                                    .add(
                                                      LoadPaymentsEvent(
                                                        filterStatus:
                                                            _selectedStatus,
                                                      ),
                                                    );
                                              },
                                            )
                                          : null,
                                    ),
                                    onChanged: (query) {
                                      context.read<PaymentsBloc>().add(
                                        LoadPaymentsEvent(
                                          searchQuery: query,
                                          filterStatus: _selectedStatus,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Text(
                                  'Filter Payment Status: ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.mediumGray,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('All Payments'),
                                  selected: _selectedStatus == null,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedStatus = null);
                                      context.read<PaymentsBloc>().add(
                                        LoadPaymentsEvent(
                                          searchQuery: _searchController.text,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                ...PaymentStatus.values.map((status) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(status.label),
                                      selected: _selectedStatus == status,
                                      onSelected: (selected) {
                                        setState(
                                          () => _selectedStatus = selected
                                              ? status
                                              : null,
                                        );
                                        context.read<PaymentsBloc>().add(
                                          LoadPaymentsEvent(
                                            searchQuery: _searchController.text,
                                            filterStatus: _selectedStatus,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payments Table
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
                              searchQuery: _searchController.text,
                              filterStatus: _selectedStatus,
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
}
