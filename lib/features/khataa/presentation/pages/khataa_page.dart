import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/shared/widgets/app_filter_widgets.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class KhataaPage extends StatefulWidget {
  const KhataaPage({Key? key}) : super(key: key);

  @override
  State<KhataaPage> createState() => _KhataaPageState();
}

class _KhataaPageState extends State<KhataaPage> {
  // ── Filter state ────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _statusFilter; // null == "All"

  // ── Static ledger data ──────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _khataaLedger = [
    {
      'id': '1',
      'name': 'Hafiz Muhammad Bilal',
      'phone': '0300-1234567',
      'totalBill': 3500.0,
      'paidAmount': 1500.0,
      'remainingAmount': 2000.0,
      'lastPaymentDate': 'May 10, 2026',
      'dueStatus': 'Overdue',
    },
    {
      'id': '2',
      'name': 'Kamran Khan Kyani',
      'phone': '0312-9876543',
      'totalBill': 1499.0,
      'paidAmount': 1499.0,
      'remainingAmount': 0.0,
      'lastPaymentDate': 'May 19, 2026',
      'dueStatus': 'Paid',
    },
    {
      'id': '3',
      'name': 'Zia-ur-Rehman Malik',
      'phone': '0333-5558881',
      'totalBill': 4500.0,
      'paidAmount': 2000.0,
      'remainingAmount': 2500.0,
      'lastPaymentDate': 'May 08, 2026',
      'dueStatus': 'Overdue',
    },
    {
      'id': '4',
      'name': 'Dr. Sajid Mehmood',
      'phone': '0321-4443332',
      'totalBill': 2499.0,
      'paidAmount': 1000.0,
      'remainingAmount': 1499.0,
      'lastPaymentDate': 'May 12, 2026',
      'dueStatus': 'Partial',
    },
    {
      'id': '5',
      'name': 'Mian Farooq Ahmed',
      'phone': '0345-6667779',
      'totalBill': 999.0,
      'paidAmount': 999.0,
      'remainingAmount': 0.0,
      'lastPaymentDate': 'May 15, 2026',
      'dueStatus': 'Paid',
    },
  ];

  final List<Map<String, dynamic>> _ledgerTimeline = [
    {
      'date': 'May 19, 2026',
      'customer': 'Kamran Khan Kyani',
      'amount': 1499.0,
      'notes': 'Cleared previous package remaining dues',
      'operator': 'Nasr Ullah',
    },
    {
      'date': 'May 15, 2026',
      'customer': 'Mian Farooq Ahmed',
      'amount': 999.0,
      'notes': 'Full advance package payment',
      'operator': 'Nasr Ullah',
    },
    {
      'date': 'May 12, 2026',
      'customer': 'Dr. Sajid Mehmood',
      'amount': 1000.0,
      'notes': 'Partial installment payment for router installation',
      'operator': 'Nasr Ullah',
    },
  ];

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Returns the number of active filters (search + status).
  int get _activeFilterCount {
    int count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_statusFilter != null) count++;
    return count;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _statusFilter = null;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Dialogs / actions ────────────────────────────────────────────────────────

  void _recordPartialPayment(Map<String, dynamic> customer) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController(
      text: 'Partial collection update',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Record Khataa Cash: ${customer['name']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining Balance Due: ${DateTimeUtils.formatCurrency(customer['remainingAmount'] as double)}',
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppFormField(
                    label: 'Amount Collected (Rs.)',
                    controller: amountController,
                    hintText: 'e.g. 1000',
                    keyboardType: TextInputType.number,
                    isRequired: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter amount';
                      final amt = double.tryParse(v);
                      if (amt == null || amt <= 0)
                        return 'Enter valid positive number';
                      if (amt > customer['remainingAmount'])
                        return 'Cannot collect more than balance due';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppFormField(
                    label: 'Payment Ledger Note',
                    controller: notesController,
                    hintText: 'e.g. Paid cash at office counter',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.mediumGray),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final amt = double.parse(amountController.text);
                  setState(() {
                    customer['paidAmount'] =
                        (customer['paidAmount'] as double) + amt;
                    customer['remainingAmount'] =
                        (customer['remainingAmount'] as double) - amt;
                    customer['lastPaymentDate'] = 'Today';
                    customer['dueStatus'] = customer['remainingAmount'] == 0
                        ? 'Paid'
                        : 'Partial';

                    _ledgerTimeline.insert(0, {
                      'date': 'Today',
                      'customer': customer['name'],
                      'amount': amt,
                      'notes': notesController.text.trim(),
                      'operator': 'Nasr Ullah',
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Khataa payment entry updated!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              child: const Text('Save Entry'),
            ),
          ],
        );
      },
    );
  }

  void _sendReminder(Map<String, dynamic> customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'WhatsApp Payment Reminder sent to ${customer['name']} '
          '(${customer['phone']}) successfully!',
        ),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: Text('Not authenticated'));
        }

        // ── Filtering logic (unchanged) ──────────────────────────────────────
        final filteredLedger = _khataaLedger.where((item) {
          final matchesSearch = item['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
          final matchesFilter =
              _statusFilter == null || item['dueStatus'] == _statusFilter;
          return matchesSearch && matchesFilter;
        }).toList();

        // ── Summary metrics (unchanged) ──────────────────────────────────────
        final double totalOutstanding = _khataaLedger.fold(
          0.0,
          (sum, item) => sum + (item['remainingAmount'] as double),
        );
        final int overdueCount = _khataaLedger
            .where((item) => item['dueStatus'] == 'Overdue')
            .length;
        final int pendingCount = _khataaLedger
            .where((item) => (item['remainingAmount'] as double) > 0)
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Breadcrumb ─────────────────────────────────────────────────
              Breadcrumb(
                items: [
                  BreadcrumbItem(
                    label: 'Home',
                    onTap: () => context.go(RoutePaths.dashboard),
                  ),
                  BreadcrumbItem(label: 'Khataa Ledger'),
                ],
              ),
              const SizedBox(height: 16),

              // ── Page header ────────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Khataa Ledger',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track manual monthly balances, partial cash collections, '
                    'and outstanding dues from local subscribers.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Summary metric cards ───────────────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  return GridView.count(
                    crossAxisCount: isDesktop ? 3 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isDesktop ? 2.5 : 1.5,
                    children: [
                      _buildSummaryCard(
                        'Total Outstanding Dues',
                        DateTimeUtils.formatCurrency(totalOutstanding),
                        'Remaining cash collections pending',
                        Icons.account_balance_wallet,
                        AppTheme.errorColor,
                      ),
                      _buildSummaryCard(
                        'Customers with Balance Due',
                        '$pendingCount Accounts',
                        'Accounts with non-zero dues',
                        Icons.people,
                        AppTheme.warningColor,
                      ),
                      _buildSummaryCard(
                        'Severe Overdue Accounts',
                        '$overdueCount Accounts',
                        'Passed grace billing periods',
                        Icons.assignment_late,
                        Colors.redAccent,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── REFACTORED: Centralized filter section ─────────────────────
              AppFilterContainer(
                title: 'Search & Filter',
                titleIcon: Icons.manage_search_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search field
                    AppSearchField(
                      controller: _searchController,
                      hintText: 'Search customer ledger by name...',
                      onChanged: (val) => setState(() => _searchQuery = val),
                      onClear: () => setState(() => _searchQuery = ''),
                    ),
                    const SizedBox(height: 14),

                    // Status chips + badge + clear — all in one responsive row
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppStatusChipGroup(
                          options: const ['Overdue', 'Partial', 'Paid'],
                          selected: _statusFilter,
                          onChanged: (val) =>
                              setState(() => _statusFilter = val),
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
              ),
              const SizedBox(height: 24),

              // ── Ledger table ───────────────────────────────────────────────
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Customer Ledger Book (Khataa)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Divider(),
                    DataTableWrapper(
                      columns: const [
                        DataColumn(label: Text('Customer Name')),
                        DataColumn(label: Text('Total Bill (Rs.)')),
                        DataColumn(label: Text('Paid Amount (Rs.)')),
                        DataColumn(label: Text('Remaining Dues')),
                        DataColumn(label: Text('Last Payment Date')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filteredLedger.map((item) {
                        final remaining = item['remainingAmount'] as double;
                        final total = item['totalBill'] as double;
                        final paid = item['paidAmount'] as double;

                        Color statusColor = AppTheme.successColor;
                        if (item['dueStatus'] == 'Overdue') {
                          statusColor = AppTheme.errorColor;
                        } else if (item['dueStatus'] == 'Partial') {
                          statusColor = AppTheme.warningColor;
                        }

                        return DataRow(
                          cells: [
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    item['phone'] as String,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.mediumGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(DateTimeUtils.formatCurrency(total))),
                            DataCell(Text(DateTimeUtils.formatCurrency(paid))),
                            DataCell(
                              Text(
                                DateTimeUtils.formatCurrency(remaining),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: remaining > 0
                                      ? AppTheme.errorColor
                                      : AppTheme.successColor,
                                ),
                              ),
                            ),
                            DataCell(Text(item['lastPaymentDate'] as String)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item['dueStatus'] as String,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (remaining > 0) ...[
                                    IconButton(
                                      tooltip: 'Log Cash Received',
                                      icon: const Icon(
                                        Icons.add_card,
                                        color: AppTheme.primaryColor,
                                      ),
                                      onPressed: () =>
                                          _recordPartialPayment(item),
                                    ),
                                    IconButton(
                                      tooltip: 'Send Reminder Message',
                                      icon: const Icon(
                                        Icons.notification_important_rounded,
                                        color: AppTheme.warningColor,
                                      ),
                                      onPressed: () => _sendReminder(item),
                                    ),
                                  ] else
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: AppTheme.successColor,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    if (filteredLedger.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No Khataa accounts found.')),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Recent collections timeline ────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Cash Collections Log',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 24),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ledgerTimeline.length,
                        itemBuilder: (context, index) {
                          final log = _ledgerTimeline[index];
                          return ListTile(
                            dense: true,
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.successColor,
                              child: Icon(
                                Icons.account_balance,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            title: Text(
                              log['customer'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${log['notes']} - Collected by ${log['operator']}',
                            ),
                            trailing: Text(
                              '+ ${DateTimeUtils.formatCurrency(log['amount'] as double)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.successColor,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Summary card widget (unchanged) ─────────────────────────────────────────

  Widget _buildSummaryCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.mediumGray,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
