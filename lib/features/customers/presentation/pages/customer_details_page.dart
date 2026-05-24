import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class CustomerDetailsPage extends StatefulWidget {
  final String customerId;

  const CustomerDetailsPage({Key? key, required this.customerId})
    : super(key: key);

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  late CustomerModel _customer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  void _loadCustomerData() async {
    // Simulate loading data from backend DB
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final index = int.tryParse(widget.customerId.replaceAll('cust_', '')) ?? 1;
    setState(() {
      _customer = CustomerModel(
        id: widget.customerId,
        name: 'Customer ${index + 1}',
        phone: '+923001234${500 + index}',
        address: 'House $index, Street 14, Phase 2, DHA, Karachi',
        email: 'customer$index@nasr_isp.com',
        packageName: ['10 Mbps', '25 Mbps', '50 Mbps'][index % 3],
        monthlyRate: [999, 1499, 2499][index % 3].toDouble(),
        expiryDate: DateTime.now().add(Duration(days: 7 + (index % 15))),
        status: (index % 12 == 0)
            ? CustomerStatus.expired
            : ((index % 12 <= 2)
                  ? CustomerStatus.expiringSoon
                  : CustomerStatus.active),
        assignedEmployeeId: 'emp_2',
        createdAt: DateTime.now().subtract(const Duration(days: 240)),
        balance: (index % 2 == 0) ? 0 : 1500,
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: Text('Not authenticated')));
        }

        return _isLoading
            ? const LoadingWidget(
                message: 'Compiling subscriber audit trail...',
              )
            : Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Breadcrumb(
                      items: [
                        BreadcrumbItem(
                          label: 'Home',
                          onTap: () => context.go(RoutePaths.dashboard),
                        ),
                        BreadcrumbItem(
                          label: 'Customers',
                          onTap: () => context.go(RoutePaths.customers),
                        ),
                        BreadcrumbItem(label: _customer.name),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subscriber Ledger: ${_customer.name}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (authState.user.role.isAdmin)
                          OutlinedButton.icon(
                            onPressed: () => context.go(
                              '${RoutePaths.customers}/${_customer.id}/edit',
                            ),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit Account'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Main detail layouts
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 800;
                        return isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildPrimaryInfoCol(),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 2,
                                    child: _buildTimelineSidebarCol(),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildPrimaryInfoCol(),
                                  const SizedBox(height: 24),
                                  _buildTimelineSidebarCol(),
                                ],
                              );
                      },
                    ),
                  ],
                ),
              );
      },
    );
  }

  Widget _buildPrimaryInfoCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top overview row
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _customer.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${_customer.id.toUpperCase()} • Registered since ${DateTimeUtils.formatDate(_customer.createdAt)}',
                          style: const TextStyle(
                            color: AppTheme.mediumGray,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    StatusBadge(status: _customer.status),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildOverviewStat(
                      'Active Package',
                      _customer.packageName,
                      Icons.speed,
                      AppTheme.primaryColor,
                    ),
                    _buildOverviewStat(
                      'Monthly Cost',
                      DateTimeUtils.formatCurrency(_customer.monthlyRate),
                      Icons.monetization_on,
                      AppTheme.successColor,
                    ),
                    _buildOverviewStat(
                      'Plan Expiry',
                      DateTimeUtils.formatDate(_customer.expiryDate),
                      Icons.date_range,
                      AppTheme.warningColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Detail Fields
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Physical and Contact Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Divider(height: 24),
                _buildInfoRow('Contact Phone', _customer.phone),
                _buildInfoRow('Email Address', _customer.email ?? 'N/A'),
                _buildInfoRow('Physical Address', _customer.address),
                _buildInfoRow(
                  'Assigned Field tech ID',
                  _customer.assignedEmployeeId ?? 'Unassigned',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Payment history table
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPaymentHistoryTable(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mediumGray,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.mediumGray,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.darkGray,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryTable() {
    final mockPayments = [
      {
        'id': 'TXN_9921',
        'date': '2026-05-01',
        'amount': 1500.0,
        'status': PaymentStatus.completed,
        'method': 'Cash',
      },
      {
        'id': 'TXN_8812',
        'date': '2026-04-02',
        'amount': 1500.0,
        'status': PaymentStatus.completed,
        'method': 'Bank Transfer',
      },
      {
        'id': 'TXN_7761',
        'date': '2026-03-01',
        'amount': 1500.0,
        'status': PaymentStatus.completed,
        'method': 'Cash',
      },
    ];

    return DataTableWrapper(
      columns: const [
        DataColumn(label: Text('Transaction ID')),
        DataColumn(label: Text('Collection Date')),
        DataColumn(label: Text('Amount paid')),
        DataColumn(label: Text('Method')),
        DataColumn(label: Text('Status')),
      ],
      rows: mockPayments.map((pay) {
        return DataRow(
          cells: [
            DataCell(
              Text(
                pay['id'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataCell(
              Text(
                DateTimeUtils.formatDate(DateTime.parse(pay['date'] as String)),
              ),
            ),
            DataCell(
              Text(DateTimeUtils.formatCurrency(pay['amount'] as double)),
            ),
            DataCell(Text(pay['method'] as String)),
            DataCell(
              PaymentStatusBadge(status: pay['status'] as PaymentStatus),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTimelineSidebarCol() {
    final timelineEvents = [
      {
        'title': 'Billing collection verified',
        'subtitle': 'Collected amount PKR 1,500 by Technician Ali',
        'date': '2026-05-01',
      },
      {
        'title': 'Account Plan Auto-renewed',
        'subtitle': 'Package updated to ${_customer.packageName}',
        'date': '2026-05-01',
      },
      {
        'title': 'Reported packet loss issue',
        'subtitle': 'Resolved by remote line resetting in 20 minutes',
        'date': '2026-04-18',
      },
      {
        'title': 'Customer details modified',
        'subtitle': 'Address detail updated by admin',
        'date': '2026-03-12',
      },
      {
        'title': 'Physical installation completed',
        'subtitle': 'ONT Router node setup by Technician Bilal',
        'date': '2025-09-23',
      },
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscriber Audit Logs',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timelineEvents.length,
              itemBuilder: (context, index) {
                final ev = timelineEvents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (index != timelineEvents.length - 1)
                            Container(
                              width: 2,
                              height: 40,
                              color: AppTheme.lightGray,
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ev['title']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.darkGray,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ev['subtitle']!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.mediumGray,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateTimeUtils.formatDate(
                                DateTime.parse(ev['date']!),
                              ),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.mediumGray,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
