import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/widgets/app_filter_widgets.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/responsive_dashboard.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';
import 'package:nasr_isp/shared/widgets/reusable_filter_components.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({Key? key}) : super(key: key);

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  late TextEditingController _searchController;

  /// null = "All" is active (default). Otherwise holds the selected
  /// status label, e.g. 'Active', 'Expiring Soon', 'Expired', 'Inactive'.
  String? _selectedStatus;

  late DateTime? _dateRangeStart;
  late DateTime? _dateRangeEnd;
  CustomerModel? _selectedCustomerForDetail;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedStatus = null; // All
    _dateRangeStart = null;
    _dateRangeEnd = null;
    context.read<CustomersBloc>().add(const LoadCustomersEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sendReminder(CustomerModel customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'WhatsApp reminder message sent to ${customer.name} (${customer.phone}) successfully!',
        ),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _dateRangeStart = null;
      _dateRangeEnd = null;
    });
    context.read<CustomersBloc>().add(const LoadCustomersEvent());
  }

  void _onStatusChanged(String? status) {
    setState(() => _selectedStatus = status);
    final filterStatus = status == null
        ? null
        : CustomerStatus.values.firstWhere((s) => s.label == status);
    context.read<CustomersBloc>().add(
      LoadCustomersEvent(
        searchQuery: _searchController.text,
        filterStatus: filterStatus,
      ),
    );
  }

  Widget _buildFilterPanel() {
    final activeFilterCount =
        (_selectedStatus != null ? 1 : 0) +
        (_searchController.text.isNotEmpty ? 1 : 0) +
        (_dateRangeStart != null ? 1 : 0) +
        (_dateRangeEnd != null ? 1 : 0);

    return AppFilterContainer(
      title: 'Search & Filter Customers',
      titleIcon: Icons.filter_list,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field with header
          FilterPanelHeader(
            searchController: _searchController,
            onSearchChanged: (query) {
              setState(() {});
              final filterStatus = _selectedStatus == null
                  ? null
                  : CustomerStatus.values.firstWhere(
                      (s) => s.label == _selectedStatus,
                    );
              context.read<CustomersBloc>().add(
                LoadCustomersEvent(
                  searchQuery: query,
                  filterStatus: filterStatus,
                ),
              );
            },
            onClearFilters: activeFilterCount > 0 ? _clearFilters : null,
            activeFilterCount: activeFilterCount,
            title: 'Active Filters',
          ),
          SizedBox(height: AppSpacing.xl),

          // Date Range Filter
          DateRangePickerField(
            startDate: _dateRangeStart,
            endDate: _dateRangeEnd,
            label: 'Expiry Date Range',
            onDateRangeChanged: (range) {
              setState(() {
                _dateRangeStart = range?.start;
                _dateRangeEnd = range?.end;
              });
            },
          ),
          SizedBox(height: AppSpacing.lg),

          // Status Filter Chips (All + statuses, single-select, reusable)
          const Text(
            'Subscription Status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          AppStatusChipGroup(
            options: CustomerStatus.values.map((s) => s.label).toList(),
            selected: _selectedStatus,
            onChanged: _onStatusChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: Text('Not authenticated'));
        }

        return BlocBuilder<CustomersBloc, CustomersState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
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
                            BreadcrumbItem(label: 'Customers'),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => context.go(RoutePaths.addCustomer),
                        icon: const Icon(
                          Icons.person_add,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text('Add Customer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 2,
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

                  // Premium Filter Panel
                  _buildFilterPanel(),
                  const SizedBox(height: 24),

                  // Main Directory Table
                  if (state is CustomersLoading)
                    const LoadingWidget(
                      message: 'Retrieving subscriber databases...',
                    )
                  else if (state is CustomersError)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error,
                              color: AppTheme.errorColor,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(state.message),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.read<CustomersBloc>().add(
                                  const LoadCustomersEvent(),
                                );
                              },
                              child: const Text('Retry Query'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (state is CustomersLoaded)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        state.customers.isEmpty
                            ? Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: const EmptyStateWidget(
                                    icon: Icons.people_outline,
                                    title: 'No Customers Found',
                                    subtitle:
                                        'Adjust your filters or add a new record to begin.',
                                  ),
                                ),
                              )
                            : ResponsiveDashboard(
                                mobile: _buildCustomerCardList(
                                  state.customers,
                                  authState.user,
                                ),
                                desktop: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildCustomersTable(
                                            state.customers,
                                            authState.user,
                                          ),
                                        ),
                                        if (_selectedCustomerForDetail !=
                                            null) ...[
                                          const SizedBox(width: 16),
                                          _buildDetailsSideSheet(
                                            _selectedCustomerForDetail!,
                                          ),
                                        ],
                                      ],
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
                              context.read<CustomersBloc>().add(
                                LoadCustomersEvent(
                                  page: page,
                                  searchQuery: state.searchQuery,
                                  filterStatus: state.filterStatus,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomersTable(
    List<CustomerModel> customers,
    UserModel currentUser,
  ) {
    return DataTableWrapper(
      columns: const [
        DataColumn(label: Text('Name / Account ID')),
        DataColumn(label: Text('Phone Number')),
        DataColumn(label: Text('Package Rate')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Expiry Date')),
        DataColumn(label: Text('Outstanding Dues')),
      ],
      rows: customers.map((customer) {
        final outstandingBalance = customer.balance ?? 0;
        final hasDebt = outstandingBalance > 0;
        final isSelected = _selectedCustomerForDetail?.id == customer.id;

        return DataRow(
          selected: isSelected,
          cells: [
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    customer.id.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(Text(customer.phone)),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    customer.packageName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateTimeUtils.formatCurrency(customer.monthlyRate),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(StatusBadge(status: customer.status)),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateTimeUtils.formatDate(customer.expiryDate)),
                  Text(
                    '${customer.daysUntilExpiry} days left',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: customer.daysUntilExpiry <= 7
                          ? AppTheme.errorColor
                          : AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(
              Text(
                DateTimeUtils.formatCurrency(outstandingBalance),
                style: TextStyle(
                  color: hasDebt ? AppTheme.errorColor : AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          onSelectChanged: (selected) {
            setState(() {
              if (selected == true) {
                _selectedCustomerForDetail = customer;
              } else {
                _selectedCustomerForDetail = null;
              }
            });
          },
        );
      }).toList(),
    );
  }

  /// Mobile: compact card-per-customer list
  Widget _buildCustomerCardList(
    List<CustomerModel> customers,
    UserModel currentUser,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: customers.map((customer) {
        final outstanding = customer.balance ?? 0.0;
        final hasDebt = outstanding > 0;
        return GestureDetector(
          onTap: () => context.go('${RoutePaths.customers}/${customer.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lightGray.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Text(
                            customer.id.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: customer.status),
                  ],
                ),
                const SizedBox(height: 10),
                // Info row
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _mobileInfoChip(Icons.speed, customer.packageName),
                    _mobileInfoChip(
                      Icons.monetization_on,
                      DateTimeUtils.formatCurrency(customer.monthlyRate),
                    ),
                    _mobileInfoChip(
                      Icons.date_range,
                      '${customer.daysUntilExpiry}d left',
                      color: customer.daysUntilExpiry <= 7
                          ? AppTheme.errorColor
                          : AppTheme.mediumGray,
                    ),
                    _mobileInfoChip(
                      Icons.account_balance_wallet,
                      DateTimeUtils.formatCurrency(outstanding),
                      color: hasDebt
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _mobileInfoChip(IconData icon, String label, {Color? color}) {
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

  Widget _buildDetailsSideSheet(CustomerModel customer) {
    final outstanding = customer.balance ?? 0.0;
    return Container(
      width: 420,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: AppTheme.lightGray, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Side sheet header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            color: AppTheme.veryLightGray,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.darkGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Account ID: ${customer.id.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.mediumGray),
                  onPressed: () =>
                      setState(() => _selectedCustomerForDetail = null),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable detail items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Quick stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(status: customer.status),
                      Text(
                        'Plan Expiry: ${DateTimeUtils.formatDate(customer.expiryDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Contact section
                  const Text(
                    'Subscriber Account Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.darkGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Phone Number', customer.phone, Icons.phone),
                  _buildDetailRow(
                    'Email Address',
                    customer.email ?? 'No email saved',
                    Icons.email,
                  ),
                  _buildDetailRow(
                    'Home Address',
                    customer.address.isEmpty
                        ? 'No address saved'
                        : customer.address,
                    Icons.home,
                  ),
                  const Divider(height: 32),

                  // Device / Hardware Assignment
                  const Text(
                    'Hardware & Fiber Line Assignment',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.darkGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Assigned Router',
                    'Fiber Home GPON ONU (Tenda F3)',
                    Icons.router,
                  ),
                  _buildDetailRow(
                    'MAC Address',
                    '4C:11:AE:9E:C1:F4',
                    Icons.settings_ethernet,
                  ),
                  _buildDetailRow(
                    'Serial Number',
                    'SN98198372727',
                    Icons.fingerprint,
                  ),
                  _buildDetailRow(
                    'Fiber Line Port',
                    'OLT PON Port 4 - Spl. Box 3',
                    Icons.cable,
                  ),
                  const Divider(height: 32),

                  // Khataa Ledger / Dues
                  const Text(
                    'Manual Dues Ledger (Khataa Book)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.darkGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Outstanding Balance',
                    DateTimeUtils.formatCurrency(outstanding),
                    Icons.account_balance_wallet,
                    valueColor: outstanding > 0
                        ? AppTheme.errorColor
                        : AppTheme.successColor,
                  ),
                  _buildDetailRow(
                    'Monthly Package Cost',
                    DateTimeUtils.formatCurrency(customer.monthlyRate),
                    Icons.monetization_on,
                  ),
                  _buildDetailRow(
                    'Last Collection Entry',
                    'May 10, 2026',
                    Icons.event,
                  ),
                  _buildDetailRow(
                    'Account Book Note',
                    'Customer pays cash via router installer',
                    Icons.sticky_note_2,
                  ),

                  const SizedBox(height: 32),

                  // Actions
                  if (outstanding > 0)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.warningColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _sendReminder(customer),
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Send Dues Reminder (WhatsApp)'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.mediumGray),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: AppTheme.mediumGray),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppTheme.darkGray,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
