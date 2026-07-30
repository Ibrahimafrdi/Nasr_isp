import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_bloc.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_state.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_event.dart';
import 'package:nasr_isp/features/installations/presentation/bloc/installations_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';

class CustomerDetailsPage extends StatefulWidget {
  final String customerId;

  const CustomerDetailsPage({Key? key, required this.customerId})
    : super(key: key);

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  CustomerModel? _customer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
    // Also trigger package load to ensure package info is available for lookups
    context.read<PackagesBloc>().add(const LoadPackagesEvent());
    // Load installations for this subscriber
    context.read<InstallationBloc>().add(
      LoadCustomerInstallationsEvent(widget.customerId),
    );
  }

  Future<void> _loadCustomer() async {
    final customersState = context.read<CustomersBloc>().state;

    // First try BLoC state (fast path) — scoped so a miss here falls
    // through to the fallback reload below instead of failing outright.
    if (customersState is CustomersLoaded) {
      CustomerModel? found;
      try {
        found = customersState.customers.firstWhere(
          (c) => c.id == widget.customerId,
        );
      } catch (_) {
        // Not in the currently loaded (possibly filtered/paginated) page —
        // fall through to the fallback reload below.
      }
      if (found != null) {
        if (mounted) {
          setState(() {
            _customer = found;
            _isLoading = false;
          });
        }
        return;
      }
    }

    // Fallback: reload all customers via BLoC and wait
    try {
      context.read<CustomersBloc>().add(const LoadCustomersEvent());
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      final newState = context.read<CustomersBloc>().state;
      if (newState is CustomersLoaded) {
        final found = newState.customers.firstWhere(
          (c) => c.id == widget.customerId,
          orElse: () => throw Exception('Customer not found'),
        );
        setState(() {
          _customer = found;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Could not load customer data.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Customer not found.';
        _isLoading = false;
      });
    }
  }

  String _getPackageName(String? packageId) {
    if (packageId == null || packageId.isEmpty) return 'No Package';
    final state = context.read<PackagesBloc>().state;
    if (state is PackagesLoaded) {
      for (final pkg in state.packages) {
        if (pkg.id == packageId) {
          return pkg.name;
        }
      }
    }
    return 'Plan ID: $packageId';
  }

  /// The loaded customer's monthly subscription margin, carrying a verdict on
  /// whether the package behind it actually resolved. Only call once
  /// [_customer] is non-null.
  SubscriberMargin get _monthlyMargin =>
      _customer!.monthlyMargin(_getCustomerPackage(_customer!.packageId));

  PackageEntity? _getCustomerPackage(String? packageId) {
    if (packageId == null || packageId.isEmpty) return null;
    final state = context.read<PackagesBloc>().state;
    if (state is PackagesLoaded) {
      for (final pkg in state.packages) {
        if (pkg.id == packageId) {
          return pkg;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: Text('Not authenticated')));
        }

        if (_isLoading) {
          return const LoadingWidget(
            message: 'Compiling subscriber audit trail...',
          );
        }

        if (_errorMessage != null || _customer == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 12),
                Text(_errorMessage ?? 'Customer not found.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go(RoutePaths.customers),
                  child: const Text('Back to Customers'),
                ),
              ],
            ),
          );
        }

        final isMobile = Responsive.isMobile(context);

        return SingleChildScrollView(
          padding: EdgeInsets.all(
            isMobile ? AppConstants.paddingMedium : AppConstants.paddingLarge,
          ),
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
                  BreadcrumbItem(label: _customer!.name),
                ],
              ),
              const SizedBox(height: 12),

              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subscriber Ledger',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _customer!.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.mediumGray),
                        ),
                        if (authState.user.isAdmin) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => context.go(
                              '${RoutePaths.customers}/${_customer!.id}/edit',
                            ),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit Account'),
                          ),
                        ],
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Subscriber Ledger: ${_customer!.name}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (authState.user.isAdmin)
                          OutlinedButton.icon(
                            onPressed: () => context.go(
                              '${RoutePaths.customers}/${_customer!.id}/edit',
                            ),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit Account'),
                          ),
                      ],
                    ),

              const SizedBox(height: 20),

              ResponsiveSwitcher(
                mobile: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrimaryInfoCol(authState.user.isAdmin),
                    const SizedBox(height: 24),
                    _buildTimelineSidebarCol(authState.user.isAdmin),
                  ],
                ),
                desktop: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildPrimaryInfoCol(authState.user.isAdmin),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: _buildTimelineSidebarCol(authState.user.isAdmin),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrimaryInfoCol(bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverviewCard(isAdmin),
        const SizedBox(height: 24),
        _buildContactDetailsCard(isAdmin),
        const SizedBox(height: 24),
        _buildInstallationHistoryCard(isAdmin),
        if (isAdmin) ...[
          const SizedBox(height: 24),
          _buildPaymentHistoryCard(),
        ],
      ],
    );
  }

  Widget _buildOverviewCard(bool isAdmin) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _customer!.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${_customer!.id.toUpperCase()} · Since ${DateTimeUtils.formatDate(_customer!.createdAt ?? DateTime.now())}',
                        style: const TextStyle(
                          color: AppTheme.mediumGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                StatusBadge(status: _customer!.status),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 480;
                final stats = [
                  _overviewStatData(
                    'Active Package',
                    _getPackageName(_customer!.packageId),
                    Icons.speed,
                    AppTheme.primaryColor,
                  ),
                  if (isAdmin) ...[
                    _overviewStatData(
                      'Monthly Bill',
                      DateTimeUtils.formatCurrency(_customer!.monthlyBill),
                      Icons.monetization_on,
                      AppTheme.successColor,
                    ),
                    _overviewStatData(
                      'Package Cost',
                      _monthlyMargin.isReliable
                          ? DateTimeUtils.formatCurrency(
                              _monthlyMargin.money.costIncurred)
                          : 'Not set',
                      Icons.cloud_download_outlined,
                      _monthlyMargin.isReliable
                          ? AppTheme.darkGray
                          : AppTheme.warningColor,
                    ),
                    _overviewStatData(
                      'Monthly Profit',
                      DateTimeUtils.formatCurrency(_monthlyMargin.money.profit),
                      Icons.trending_up,
                      // Warns whenever there is no usable package cost — no
                      // package assigned, or a packageId that no longer
                      // resolves. Cost falls back to zero in both cases, so the
                      // whole bill shows as profit: an upper bound, not a fact.
                      _monthlyMargin.isReliable
                          ? AppColors.profitBlue
                          : AppTheme.warningColor,
                    ),
                  ],
                ];

                if (isNarrow) {
                  return Column(
                    children: stats
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildOverviewStatWidget(s),
                          ),
                        )
                        .toList(),
                  );
                }
                return Row(
                  children: stats.map(_buildOverviewStatWidget).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _overviewStatData(
    String label,
    String value,
    IconData icon,
    Color color,
  ) => {'label': label, 'value': value, 'icon': icon, 'color': color};

  Widget _buildOverviewStatWidget(Map<String, dynamic> s) {
    return Expanded(
      child: Row(
        children: [
          Icon(s['icon'] as IconData, color: s['color'] as Color, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['label'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.mediumGray,
                  ),
                ),
                Text(
                  s['value'] as String,
                  style: const TextStyle(
                    fontSize: 13,
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

  Widget _buildContactDetailsCard(bool isAdmin) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscriber Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Connection Type',
              _customer!.connectionType == 'fiber' ? 'Fiber' : 'Wireless',
              Icons.settings_input_antenna,
            ),
            _buildInfoRow(
              'Monthly Bill Rate',
              DateTimeUtils.formatCurrency(_customer!.monthlyBill),
              Icons.receipt_long,
            ),
            _buildInfoRow('Contact Phone', _customer!.phone, Icons.phone),
            _buildInfoRow('CNIC / National ID', _customer!.cnic, Icons.badge),
            _buildInfoRow(
              'Physical Address',
              _customer!.address.isEmpty ? 'N/A' : _customer!.address,
              Icons.location_on,
            ),
            _buildInfoRow(
              'Notes',
              _customer!.notes.isEmpty ? 'N/A' : _customer!.notes,
              Icons.notes,
            ),
            _buildInfoRow(
              'Join Date',
              _customer!.joinDate != null
                  ? DateTimeUtils.formatDate(_customer!.joinDate!)
                  : 'N/A',
              Icons.calendar_today,
            ),
            _buildInfoRow(
              'Next Due Date',
              () {
                final due =
                    _customer!.nextDueDate ??
                    (_customer!.createdAt != null
                        ? DateTime(
                            _customer!.createdAt!.year,
                            _customer!.createdAt!.month + 1,
                            _customer!.createdAt!.day,
                          )
                        : null);
                return due != null ? DateTimeUtils.formatDate(due) : 'N/A';
              }(),
              Icons.event,
              isEstimated:
                  _customer!.nextDueDate == null &&
                  _customer!.createdAt != null,
              valueColor: () {
                final due =
                    _customer!.nextDueDate ??
                    (_customer!.createdAt != null
                        ? DateTime(
                            _customer!.createdAt!.year,
                            _customer!.createdAt!.month + 1,
                            _customer!.createdAt!.day,
                          )
                        : null);
                if (due == null) return null;
                final diff = due.difference(DateTime.now()).inDays;
                if (diff < 0) return AppTheme.errorColor;
                if (diff <= 7) return Colors.orange;
                return null;
              }(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool isEstimated = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppTheme.mediumGray),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
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
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isEstimated)
                  Tooltip(
                    message: 'Estimated — no payment recorded yet',
                    child: const Icon(
                      Icons.info_outline,
                      size: 13,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                if (isEstimated) const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? AppTheme.darkGray,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction History',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPaymentHistoryTable(),
          ],
        ),
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

    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Column(
        children: mockPayments.map((pay) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.veryLightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pay['id'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.darkGray,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pay['method']}  ·  ${DateTimeUtils.formatDate(DateTime.parse(pay['date'] as String))}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateTimeUtils.formatCurrency(pay['amount'] as double),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    PaymentStatusBadge(status: pay['status'] as PaymentStatus),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return DataTableWrapper(
      columns: const [
        DataColumn(label: Text('Transaction ID')),
        DataColumn(label: Text('Collection Date')),
        DataColumn(label: Text('Amount')),
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

  Widget _buildTimelineSidebarCol(bool isAdmin) {
    final timelineEvents = [
      if (isAdmin)
        {
          'title': 'Billing collection verified',
          'subtitle': 'Collected amount PKR 1,500 by Installer',
          'date': '2026-05-01',
        }
      else
        {
          'title': 'Payment collected',
          'subtitle': 'Verified by Installer',
          'date': '2026-05-01',
        },
      {
        'title': 'Account Plan Auto-renewed',
        'subtitle':
            'Package updated to ${_getPackageName(_customer!.packageId)}',
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
        'subtitle': 'ONT Router node setup by Installer',
        'date': '2025-09-23',
      },
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                final isLast = index == timelineEvents.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        child: Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 42,
                                color: AppTheme.lightGray,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
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

  Widget _buildInstallationHistoryCard(bool isAdmin) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Installation History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const Divider(height: 24),
            BlocBuilder<InstallationBloc, InstallationState>(
              builder: (context, state) {
                if (state is InstallationLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (state is InstallationError) {
                  return Text('Error loading installations: ${state.message}');
                }
                if (state is InstallationLoaded) {
                  final list = state.installations;
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'No installation records found for this subscriber.',
                        style: TextStyle(
                          color: AppTheme.mediumGray,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final inst = list[index];
                      String materialsSummary = 'No materials logged';
                      if (inst.itemsUsed != null &&
                          inst.itemsUsed!.isNotEmpty) {
                        materialsSummary = inst.itemsUsed!
                            .map((i) => '${i.itemName} (x${i.quantity})')
                            .join(', ');
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Installation on ${DateTimeUtils.formatDate(inst.installationDate)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getInstallationStatusColor(
                                      inst.status,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    inst.status.displayName,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: _getInstallationStatusColor(
                                        inst.status,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Installer: ${inst.assignedEmployeeName ?? "Unassigned"}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.darkGray,
                              ),
                            ),
                            Text(
                              'BOM: $materialsSummary',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.mediumGray,
                              ),
                            ),
                            Text(
                              'Setup Fee: ${DateTimeUtils.formatCurrency(inst.installationCost)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.darkGray,
                              ),
                            ),
                            // Materials are billed on top of the setup fee, so
                            // the fee alone is not what the customer owes.
                            if (inst.materialRevenue > 0)
                              Text(
                                'Materials Billed: ${DateTimeUtils.formatCurrency(inst.materialRevenue)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.darkGray,
                                ),
                              ),
                            Text(
                              'Total Billed: ${DateTimeUtils.formatCurrency(inst.money.amountBilled)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkGray,
                              ),
                            ),
                            if (isAdmin) ...[
                              if (inst.materialCost != null)
                                Text(
                                  'Material Cost: ${DateTimeUtils.formatCurrency(inst.materialCost!)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.darkGray,
                                  ),
                                ),
                              Text(
                                'Profit: ${DateTimeUtils.formatCurrency(inst.profit)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  // Neutral when no costs were logged: exact,
                                  // but it assumes zero cost.
                                  color: !inst.hasCostData
                                      ? AppTheme.darkGray
                                      : (inst.profit >= 0
                                          ? AppTheme.successColor
                                          : AppTheme.errorColor),
                                ),
                              ),
                            ],
                            if (inst.remarks != null &&
                                inst.remarks!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Remarks: ${inst.remarks}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.mediumGray,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                }
                return const Text('Initial state');
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getInstallationStatusColor(InstallationStatus status) {
    switch (status) {
      case InstallationStatus.pending:
        return AppTheme.warningColor;
      case InstallationStatus.inProgress:
        return AppColors.primaryBlue;
      case InstallationStatus.completed:
        return AppTheme.successColor;
      case InstallationStatus.cancelled:
        return AppTheme.errorColor;
    }
  }
}
