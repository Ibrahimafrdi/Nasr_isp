import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({Key? key}) : super(key: key);

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  late TextEditingController _searchController;
  CustomerStatus? _selectedStatus;
  CustomerModel? _selectedCustomerForDetail;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
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
                        icon: const Icon(Icons.person_add, size: 18, color: Colors.white),
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

                  // Search and Filters header card
                  Card(
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
                                        'Filter by subscriber name, cell phone number, or package speed...',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _searchController.clear();
                                              context.read<CustomersBloc>().add(
                                                LoadCustomersEvent(
                                                  filterStatus: _selectedStatus,
                                                ),
                                              );
                                            },
                                          )
                                        : null,
                                  ),
                                  onChanged: (query) {
                                    context.read<CustomersBloc>().add(
                                      LoadCustomersEvent(
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
                          Builder(
                            builder: (context) {
                              final int activeFilterCount = (_selectedStatus != null ? 1 : 0) +
                                  (_searchController.text.isNotEmpty ? 1 : 0);

                              return Wrap(
                                alignment: WrapAlignment.start,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Filter Status: ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.charcoal,
                                        ),
                                      ),
                                      if (activeFilterCount > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryBlue.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Active: $activeFilterCount',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  HoverFilterChip(
                                    label: 'All Statuses',
                                    selected: _selectedStatus == null,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _selectedStatus = null);
                                        context.read<CustomersBloc>().add(
                                          LoadCustomersEvent(
                                            searchQuery: _searchController.text,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  ...CustomerStatus.values.map((status) {
                                    return HoverFilterChip(
                                      label: status.label,
                                      selected: _selectedStatus == status,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedStatus = selected ? status : null;
                                        });
                                        context.read<CustomersBloc>().add(
                                          LoadCustomersEvent(
                                            searchQuery: _searchController.text,
                                            filterStatus: _selectedStatus,
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                  if (activeFilterCount > 0) ...[
                                    const SizedBox(width: 4),
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _selectedStatus = null;
                                          _searchController.clear();
                                        });
                                        context.read<CustomersBloc>().add(
                                          const LoadCustomersEvent(),
                                        );
                                      },
                                      icon: const Icon(Icons.clear_all, size: 18, color: AppColors.errorRed),
                                      label: const Text(
                                        'Clear Filters',
                                        style: TextStyle(
                                          color: AppColors.errorRed,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
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
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: state.customers.isEmpty
                                ? const EmptyStateWidget(
                                    icon: Icons.people_outline,
                                    title: 'No Customers Found',
                                    subtitle:
                                        'Adjust your filters or add a new record to begin.',
                                  )
                                : _buildCustomersTable(
                                    state.customers,
                                    authState.user,
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
                    customer.address ?? 'No address saved',
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

class HoverFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const HoverFilterChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<HoverFilterChip> createState() => _HoverFilterChipState();
}

class _HoverFilterChipState extends State<HoverFilterChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color selectedBgColor = AppColors.primaryBlue;
    final Color selectedTextColor = Colors.white;
    final Color hoveredBgColor = AppColors.primaryBlue.withOpacity(0.08);
    final Color normalBgColor = AppColors.offWhite;

    final Color bgColor = widget.selected 
        ? selectedBgColor 
        : (_isHovered ? hoveredBgColor : normalBgColor);

    final Color textColor = widget.selected 
        ? selectedTextColor 
        : (widget.selected || _isHovered ? AppColors.primaryBlue : AppColors.charcoal);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onSelected(!widget.selected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.selected 
                  ? selectedBgColor 
                  : (_isHovered ? AppColors.primaryBlue.withOpacity(0.3) : AppColors.lightGray),
              width: 1.5,
            ),
            boxShadow: widget.selected 
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : (_isHovered 
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : []),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: textColor,
              fontWeight: widget.selected || _isHovered ? FontWeight.bold : FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}
