import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/core/utils/input_formatters.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:nasr_isp/features/payments/presentation/widgets/payment_card_list.dart';
import 'package:nasr_isp/features/payments/presentation/widgets/payment_filter_panel.dart';
import 'package:nasr_isp/features/payments/presentation/widgets/payment_stats_cards.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

/// Explains where charges come from, now that this page no longer creates
/// them.
///
/// The old "Add Payment" button let an operator invent a charge here, which
/// duplicated first-month billing from Add Customer and competed with the
/// renewal flow for ownership of the expiry date. This ledger is now read-only
/// apart from settling arrears.
class _LedgerOriginNotice extends StatelessWidget {
  const _LedgerOriginNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppTheme.darkGray,
                ),
                children: const [
                  TextSpan(
                    text: 'Charges are raised where the work happens. ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text:
                        'The first month is billed when the account is created, '
                        'and every month after that by Renew on the Customers '
                        'page — which is also the only place the expiry date '
                        'moves. Use Settle here to collect an outstanding '
                        'balance on a charge that was only part paid.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

  // ── Filter panel handlers ───────────────────────────────────────────────────
  void _onSearchChanged(String val) {
    setState(() => _searchQuery = val);
    context.read<PaymentsBloc>().add(LoadPaymentsEvent(searchQuery: val));
  }

  void _onStatusFilterChanged(String? val) {
    setState(() => _statusFilter = val);
    context.read<PaymentsBloc>().add(
      LoadPaymentsEvent(
        filterStatuses: val != null ? [val] : null,
        searchQuery: _searchQuery,
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
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (state is PaymentsLoaded) ...[
                    // Stats cards — admin only
                    if (authState.user.role == 'admin') ...[
                      const _LedgerOriginNotice(),
                      const SizedBox(height: 16),
                      PaymentStatsCards(
                        totalAmount: state.totalAmount,
                        collectedAmount: state.collectedAmount,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Filter panel
                    PaymentFilterPanel(
                      searchController: _searchController,
                      selectedStatus: _statusFilter,
                      activeFilterCount: _activeFilterCount,
                      hasDateRange:
                          _dateRangeStart != null && _dateRangeEnd != null,
                      dateRangeLabel:
                          (_dateRangeStart != null && _dateRangeEnd != null)
                              ? '${DateTimeUtils.formatDate(_dateRangeStart!)}  →  ${DateTimeUtils.formatDate(_dateRangeEnd!)}'
                              : null,
                      onSearchChanged: _onSearchChanged,
                      onStatusChanged: _onStatusFilterChanged,
                      onPickDateRange: _pickDateRange,
                      onClearDateRange: () => setState(() {
                        _dateRangeStart = null;
                        _dateRangeEnd = null;
                      }),
                      onClearFilters: _clearFilters,
                    ),
                    const SizedBox(height: 24),

                    // Payments list
                    state.payments.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.receipt_long,
                            title: 'No Payments In Selection',
                            subtitle:
                                'Modify filters or search term to discover records.',
                          )
                        : ResponsiveSwitcher(
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
        const DataColumn(label: Text('Covers To')),
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
            // The expiry this charge bought. Rows written before renewals
            // recorded a period fall back to the legacy dueDate field, which
            // held the same value under a misleading name.
            DataCell(
              Text(
                (payment.periodEnd ?? payment.dueDate) != null
                    ? DateTimeUtils.formatDate(
                        payment.periodEnd ?? payment.dueDate!)
                    : '—',
              ),
            ),
            DataCell(PaymentStatusBadge(status: payment.status)),
            DataCell(Text(payment.method ?? 'N/A')),
            if (isAdmin)
              DataCell(
                isPaid
                    ? const Tooltip(
                        message: 'Fully settled',
                        child: Icon(
                          Icons.check_circle,
                          size: 20,
                          color: AppTheme.successColor,
                        ),
                      )
                    : TextButton.icon(
                        icon: const Icon(Icons.price_check, size: 15),
                        label: const Text(
                          'Settle',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () =>
                            _showRecordPaymentDialog(context, payment),
                      ),
              ),
          ],
        );
      }).toList(),
    );
  }

  // ── Settle outstanding balance ────────────────────────────────────────────
  /// Collects arrears against a charge that was renewed on a part payment.
  ///
  /// Money only: the customer has already been granted the period this charge
  /// covers, so settling it must not move their expiry. The expiry is moved
  /// exclusively by the Renew action on the Customers page.
  void _showRecordPaymentDialog(BuildContext context, PaymentModel payment) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: payment.remainingAmount.toStringAsFixed(0),
    );
    String selectedMethod = payment.method ?? 'cash';
    String notes = '';
    bool isSubmitting = false;
    final isMobileDialog = Responsive.isMobile(context);
    final dialogTitle = 'Settle Balance: ${payment.customerName}';

    showDialog(
      context: context,
      useSafeArea: !isMobileDialog,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setState(() => isSubmitting = true);

              final received = double.parse(amountController.text.trim());
              final newPaid = payment.paidAmount + received;
              final isPaidInFull = newPaid >= payment.amount;
              final stillOwed =
                  (payment.amount - newPaid).clamp(0.0, double.infinity);

              // Dispatch first, then report — the previous order announced
              // success before the write was even queued.
              context.read<PaymentsBloc>().add(
                UpdatePaymentEvent(
                  payment.copyWith(
                    paidAmount: newPaid,
                    status: isPaidInFull ? 'paid' : 'partial',
                    // Only stamp a completion date once the charge is fully
                    // settled; a part payment leaves the charge open.
                    completedDate: isPaidInFull ? DateTime.now() : null,
                    method: selectedMethod,
                    notes: notes.isNotEmpty ? notes : null,
                  ),
                ),
              );

              await Future.delayed(const Duration(milliseconds: 800));
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isPaidInFull
                        ? '${DateTimeUtils.formatCurrency(received)} collected — '
                            '${payment.billingMonth ?? 'this charge'} is now fully settled.'
                        : '${DateTimeUtils.formatCurrency(received)} collected — '
                            '${DateTimeUtils.formatCurrency(stillOwed)} still outstanding.',
                  ),
                  backgroundColor: isPaidInFull
                      ? AppTheme.successColor
                      : Colors.orange.shade800,
                ),
              );
            }

            final formContent = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Billed for ${payment.billingMonth ?? 'this period'}: '
                  '${DateTimeUtils.formatCurrency(payment.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Already collected: '
                  '${DateTimeUtils.formatCurrency(payment.paidAmount)}',
                  style: const TextStyle(fontSize: 13),
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
                const SizedBox(height: 8),
                Text(
                  'Arrears only — this does not change the subscription '
                  'expiry, which was already extended when the customer was '
                  'renewed.',
                  style: TextStyle(fontSize: 11, color: AppTheme.mediumGray),
                ),
                const Divider(height: 24),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount Received (PKR)',
                    prefixText: 'PKR ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: AppInputFormatters.decimal,
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
                    labelText: 'Collection Reference / Notes (Optional)',
                    hintText: 'e.g. cheque number, transaction ID',
                  ),
                  onChanged: (val) => notes = val,
                ),
              ],
            );

            final saveIcon = isSubmitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 16);
            final saveLabel = Text(
              isSubmitting ? 'Recording...' : 'Record Receipt',
            );

            if (isMobileDialog) {
              return Dialog.fullscreen(
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(dialogTitle),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                    ),
                  ),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(key: formKey, child: formContent),
                  ),
                  bottomNavigationBar: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: isSubmitting ? null : submit,
                        icon: saveIcon,
                        label: saveLabel,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return AlertDialog(
              title: Text(dialogTitle),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 450,
                  child: SingleChildScrollView(child: formContent),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting ? null : submit,
                  icon: saveIcon,
                  label: saveLabel,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
