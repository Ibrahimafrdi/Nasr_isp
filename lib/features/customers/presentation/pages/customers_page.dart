import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_bloc.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_state.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_event.dart';
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
  String? _selectedStatus;
  String? _selectedConnectionType; // null = All, 'wireless', 'fiber'
  CustomerModel? _selectedCustomerForDetail;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedStatus = null; // All
    context.read<CustomersBloc>().add(const LoadCustomersEvent());
    // Also trigger package load to ensure package info is available for lookups
    context.read<PackagesBloc>().add(const LoadPackagesEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedConnectionType = null;
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
        filterConnectionType: _selectedConnectionType,
      ),
    );
  }

  void _onConnectionTypeChanged(String? type) {
    setState(() => _selectedConnectionType = type);
    final filterStatus = _selectedStatus == null
        ? null
        : CustomerStatus.values.firstWhere((s) => s.label == _selectedStatus);
    context.read<CustomersBloc>().add(
      LoadCustomersEvent(
        searchQuery: _searchController.text,
        filterStatus: filterStatus,
        filterConnectionType: type,
      ),
    );
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

  Widget _buildFilterPanel() {
    final activeFilterCount =
        (_selectedStatus != null ? 1 : 0) +
        (_searchController.text.isNotEmpty ? 1 : 0) +
        (_selectedConnectionType != null ? 1 : 0);

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
                  filterConnectionType: _selectedConnectionType,
                ),
              );
            },
            onClearFilters: activeFilterCount > 0 ? _clearFilters : null,
            activeFilterCount: activeFilterCount,
            title: 'Active Filters',
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
          const SizedBox(height: 16),
          const Text(
            'Connection Type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildConnectionChip('All', null),
              const SizedBox(width: 8),
              _buildConnectionChip('Wireless', 'wireless'),
              const SizedBox(width: 8),
              _buildConnectionChip('Fiber', 'fiber'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionChip(String label, String? value) {
    final isSelected = _selectedConnectionType == value;
    final color = value == 'fiber' ? Colors.purple : AppColors.primaryBlue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: value == null
          ? AppColors.primaryBlue.withOpacity(0.15)
          : color.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected
            ? (value == null ? AppColors.primaryBlue : color)
            : AppColors.charcoal,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? (value == null ? AppColors.primaryBlue : color)
              : Colors.grey.shade300,
        ),
      ),
      onSelected: (_) => _onConnectionTypeChanged(value),
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
                                  filterConnectionType:
                                      state.filterConnectionType,
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

  void _confirmDelete(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Customer',
        message: 'Are you sure you want to delete this customer?',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
        isDestructive: true,
        onConfirm: () {
          context.read<CustomersBloc>().add(DeleteCustomerEvent(customer.id));
          if (_selectedCustomerForDetail?.id == customer.id) {
            setState(() {
              _selectedCustomerForDetail = null;
            });
          }
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer deleted successfully.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  /// Returns nextDueDate if set, otherwise falls back to createdAt + 1 month.
  /// This is display-only — never written back to Firestore.
  DateTime? _getEffectiveDueDate(CustomerModel customer) {
    if (customer.nextDueDate != null) return customer.nextDueDate;
    if (customer.createdAt != null) {
      return DateTime(
        customer.createdAt!.year,
        customer.createdAt!.month + 1,
        customer.createdAt!.day,
      );
    }
    return null;
  }

  Widget _buildCustomersTable(
    List<CustomerModel> customers,
    UserModel currentUser,
  ) {
    return DataTableWrapper(
      columns: const [
        DataColumn(label: Text('Name / Account ID')),
        DataColumn(label: Text('Phone')),
        DataColumn(label: Text('Connection Type')),
        DataColumn(label: Text('Next Due Date')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: customers.map((customer) {
        final isSelected = _selectedCustomerForDetail?.id == customer.id;
        final dueDate = _getEffectiveDueDate(customer);

        return DataRow(
          selected: isSelected,
          color: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryBlue.withOpacity(0.06);
            }
            return null;
          }),
          cells: [
            // Name / Account ID
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    customer.id.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.mediumGray,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Phone
            DataCell(
              Text(
                customer.phone,
                style: const TextStyle(fontSize: 13, color: AppTheme.darkGray),
              ),
            ),

            // Connection Type
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: customer.connectionType == 'fiber'
                      ? Colors.purple.withOpacity(0.08)
                      : Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: customer.connectionType == 'fiber'
                        ? Colors.purple.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  customer.connectionType == 'fiber' ? 'Fiber' : 'Wireless',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: customer.connectionType == 'fiber'
                        ? Colors.purple
                        : Colors.blue[800],
                  ),
                ),
              ),
            ),

            // Next Due Date
            DataCell(() {
              if (dueDate == null) {
                return const Text(
                  '—',
                  style: TextStyle(color: AppTheme.mediumGray),
                );
              }
              final diff = dueDate.difference(DateTime.now()).inDays;
              Color color;
              String label;
              if (diff < 0) {
                color = AppTheme.errorColor;
                label = 'Overdue';
              } else if (diff == 0) {
                color = AppTheme.errorColor;
                label = 'Due Today';
              } else if (diff <= 7) {
                color = Colors.orange;
                label = 'In $diff days';
              } else {
                color = AppTheme.darkGray;
                label = '';
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateTimeUtils.formatDate(dueDate),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                  if (label.isNotEmpty)
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (customer.nextDueDate == null)
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 10,
                          color: AppTheme.mediumGray,
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'estimated',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            }()),

            // Status
            DataCell(StatusBadge(status: customer.status)),

            // Actions
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 17),
                    color: AppColors.primaryBlue,
                    tooltip: 'View Details',
                    onPressed: () {
                      setState(() => _selectedCustomerForDetail = customer);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    color: Colors.orange,
                    tooltip: 'Edit Customer',
                    onPressed: () {
                      context.go('${RoutePaths.customers}/${customer.id}/edit');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 17),
                    color: AppTheme.errorColor,
                    tooltip: 'Delete Customer',
                    onPressed: () => _confirmDelete(customer),
                  ),
                ],
              ),
            ),
          ],
          onSelectChanged: (selected) {
            setState(() {
              _selectedCustomerForDetail = selected == true ? customer : null;
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
        return Container(
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
                  _mobileInfoChip(
                    Icons.speed,
                    _getPackageName(customer.packageId),
                  ),
                  _mobileInfoChip(
                    Icons.settings_input_antenna,
                    customer.connectionType == 'fiber' ? 'Fiber' : 'Wireless',
                    color: customer.connectionType == 'fiber'
                        ? Colors.purple
                        : Colors.blue[800],
                  ),
                  if (currentUser.isAdmin)
                    _mobileInfoChip(
                      Icons.monetization_on,
                      DateTimeUtils.formatCurrency(customer.monthlyBill),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      context.go('${RoutePaths.customers}/${customer.id}');
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                    onPressed: () {
                      context.go('${RoutePaths.customers}/${customer.id}/edit');
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                    onPressed: () => _confirmDelete(customer),
                  ),
                ],
              ),
            ],
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

  Widget _sideSheetSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryBlue,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDetailsSideSheet(CustomerModel customer) {
    final authState = context.read<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;
    return Container(
      width: 460,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: AppTheme.lightGray, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Side sheet header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.veryLightGray,
              border: Border(
                bottom: BorderSide(color: AppTheme.lightGray, width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.darkGray,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        customer.id.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.mediumGray,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StatusBadge(status: customer.status),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppTheme.mediumGray,
                  ),
                  onPressed: () =>
                      setState(() => _selectedCustomerForDetail = null),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Subscriber Info ──────────────────────────
                _sideSheetSectionTitle('Subscriber Info'),
                const SizedBox(height: 10),
                _buildDetailRow('Phone', customer.phone, Icons.phone),
                _buildDetailRow('CNIC', customer.cnic, Icons.badge),
                _buildDetailRow(
                  'Address',
                  customer.address.isEmpty ? 'Not provided' : customer.address,
                  Icons.location_on,
                ),
                if (customer.notes.isNotEmpty)
                  _buildDetailRow('Notes', customer.notes, Icons.notes),

                const Divider(height: 28),

                // ── Connection & Plan ─────────────────────────
                _sideSheetSectionTitle('Connection & Plan'),
                const SizedBox(height: 10),
                _buildDetailRow(
                  'Type',
                  customer.connectionType == 'fiber' ? 'Fiber' : 'Wireless',
                  Icons.settings_input_antenna,
                ),
                _buildDetailRow(
                  'Package',
                  _getPackageName(customer.packageId),
                  Icons.speed,
                ),
                if (isAdmin) ...[
                  _buildDetailRow(
                    'Monthly Bill',
                    DateTimeUtils.formatCurrency(customer.monthlyBill),
                    Icons.receipt_long,
                  ),
                ],

                const Divider(height: 28),

                // ── Billing Dates ─────────────────────────────
                _sideSheetSectionTitle('Billing'),
                const SizedBox(height: 10),
                _buildDetailRow(
                  'Join Date',
                  customer.joinDate != null
                      ? DateTimeUtils.formatDate(customer.joinDate!)
                      : 'N/A',
                  Icons.calendar_today,
                ),
                _buildDetailRow(
                  'Next Due Date',
                  () {
                    final due =
                        customer.nextDueDate ??
                        (customer.createdAt != null
                            ? DateTime(
                                customer.createdAt!.year,
                                customer.createdAt!.month + 1,
                                customer.createdAt!.day,
                              )
                            : null);
                    return due != null ? DateTimeUtils.formatDate(due) : 'N/A';
                  }(),
                  Icons.event,
                  valueColor: () {
                    final due =
                        customer.nextDueDate ??
                        (customer.createdAt != null
                            ? DateTime(
                                customer.createdAt!.year,
                                customer.createdAt!.month + 1,
                                customer.createdAt!.day,
                              )
                            : null);
                    if (due == null) return null;
                    final diff = due.difference(DateTime.now()).inDays;
                    if (diff < 0) return AppTheme.errorColor;
                    if (diff <= 7) return Colors.orange;
                    return null;
                  }(),
                ),

                const SizedBox(height: 16),

                // ── Quick Actions ─────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontSize: 13),
                        ),
                        onPressed: () {
                          context.go(
                            '${RoutePaths.customers}/${customer.id}/edit',
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 15),
                        label: const Text(
                          'Delete',
                          style: TextStyle(fontSize: 13),
                        ),
                        onPressed: () => _confirmDelete(customer),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: BorderSide(color: AppTheme.errorColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
    bool isEstimated = false,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isEstimated)
                  Tooltip(
                    message: 'Estimated — no payment recorded yet',
                    child: const Icon(
                      Icons.info_outline,
                      size: 12,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                if (isEstimated) const SizedBox(width: 4),
                Flexible(
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
          ),
        ],
      ),
    );
  }
}
