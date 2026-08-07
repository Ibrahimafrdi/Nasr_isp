import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/features/customers/presentation/widgets/customer_card_list.dart';
import 'package:nasr_isp/features/customers/presentation/widgets/customer_details_side_sheet.dart';
import 'package:nasr_isp/features/customers/presentation/widgets/customer_filter_panel.dart';
import 'package:nasr_isp/features/customers/presentation/widgets/customer_status_dialogs.dart';
import 'package:nasr_isp/features/customers/presentation/widgets/renew_subscription_dialog.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_bloc.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_state.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_event.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
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
  String? _selectedStatus;
  String? _selectedConnectionType; // null = All, 'wireless', 'fiber'
  CustomerModel? _selectedCustomerForDetail;
  Timer? _searchDebounce;

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
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedConnectionType = null;
    });
    context.read<CustomersBloc>().add(const LoadCustomersEvent());
  }

  void _onStatusChanged(String? status) {
    _searchDebounce?.cancel();
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
    _searchDebounce?.cancel();
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

  void _onSearchChanged(String query) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppConstants.debounceDelay, () {
      if (!mounted) return;
      final filterStatus = _selectedStatus == null
          ? null
          : CustomerStatus.values.firstWhere((s) => s.label == _selectedStatus);
      context.read<CustomersBloc>().add(
        LoadCustomersEvent(
          searchQuery: query,
          filterStatus: filterStatus,
          filterConnectionType: _selectedConnectionType,
        ),
      );
    });
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
              padding: Responsive.pagePaddingFor(Responsive.deviceTypeOf(context)),
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
                  CustomerFilterPanel(
                    searchController: _searchController,
                    selectedStatus: _selectedStatus,
                    selectedConnectionType: _selectedConnectionType,
                    activeFilterCount:
                        (_selectedStatus != null ? 1 : 0) +
                        (_searchController.text.isNotEmpty ? 1 : 0) +
                        (_selectedConnectionType != null ? 1 : 0),
                    onSearchChanged: _onSearchChanged,
                    onStatusChanged: _onStatusChanged,
                    onConnectionTypeChanged: _onConnectionTypeChanged,
                    onClearFilters: _clearFilters,
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
                    Builder(builder: (context) {
                      // Re-resolve the open side sheet against the freshly
                      // loaded list. Holding the captured instance would leave
                      // it showing the pre-renewal due date after a renewal
                      // reloads the page behind it.
                      final selected = _selectedCustomerForDetail == null
                          ? null
                          : state.customers
                              .where((c) => c.id == _selectedCustomerForDetail!.id)
                              .firstOrNull;
                      return Column(
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
                            : ResponsiveSwitcher(
                                mobile: CustomerCardList(
                                  customers: state.customers,
                                  currentUser: authState.user,
                                  getPackageName: _getPackageName,
                                  onDelete: _confirmDelete,
                                  onRenew: _renew,
                                  onToggleStatus: _toggleStatus,
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
                                        if (selected != null) ...[
                                          const SizedBox(width: 16),
                                          CustomerDetailsSideSheet(
                                            customer: selected,
                                            isAdmin: authState.user.isAdmin,
                                            getPackageName: _getPackageName,
                                            onClose: () => setState(() => _selectedCustomerForDetail = null),
                                            onDelete: _confirmDelete,
                                            onRenew: _renew,
                                            onToggleStatus: _toggleStatus,
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
                    );
                    }),
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

  void _renew(CustomerModel customer) {
    showRenewSubscriptionDialog(
      context,
      customer: customer,
      packageName: _getPackageName(customer.packageId),
    );
  }

  Future<void> _toggleStatus(CustomerModel customer) async {
    final bloc = context.read<CustomersBloc>();
    final changed = await showCustomerStatusDialog(
      context,
      customer: customer,
    );
    if (!changed || !mounted) return;
    // The side sheet holds a snapshot the reload is about to make stale, and
    // it is the surface the toggle was most likely pressed from. Closing it
    // is simpler than re-resolving the row out of the incoming page.
    if (_selectedCustomerForDetail?.id == customer.id) {
      setState(() => _selectedCustomerForDetail = null);
    }

    await bloc.stream.firstWhere(
      (s) => s is CustomersLoaded || s is CustomersError,
    );
    if (!mounted) return;

    // A fresh-cycle reactivation raises a charge the operator now has to
    // collect, and can fail to raise one at all — either way they need telling.
    final outcome = bloc.lastStatusChange;
    if (outcome == null) return;
    final report = describeStatusChange(outcome);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(report.message),
        backgroundColor: report.isWarning
            ? AppTheme.warningColor
            : AppTheme.successColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Widget _buildCustomersTable(
    List<CustomerModel> customers,
    UserModel currentUser,
  ) {
    final now = DateTime.now();
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
        // Null while off service — an inactive account is not accruing a bill,
        // so the cell reads "Not billing" rather than an arrears figure.
        final dueDate = customer.billingDueDate;
        final isDueForRenewal = customer.isDueForRenewalAt(now);
        final isExpired = customer.isExpiredAt(now);

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
                return Text(
                  customer.isActive ? '—' : 'Not billing',
                  style: const TextStyle(
                    color: AppTheme.mediumGray,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                );
              }
              final diff = BillingCycle.daysUntilDue(dueDate, now);
              Color color;
              String label;
              if (diff < 0) {
                color = AppTheme.errorColor;
                label = 'Overdue by ${-diff}d';
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
                  // Renewal is the primary action on an expiring or lapsed
                  // account, so it leads the row and is filled rather than
                  // ghosted. It is the only control that moves the expiry.
                  if (isDueForRenewal)
                    Tooltip(
                      message: isExpired
                          ? 'Expired — collect payment and renew'
                          : 'Renew early',
                      child: TextButton.icon(
                        icon: const Icon(Icons.autorenew, size: 15),
                        label: const Text(
                          'Renew',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: isExpired
                              ? AppTheme.errorColor
                              : Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _renew(customer),
                      ),
                    ),
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
                    icon: Icon(
                      customer.isActive
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 17,
                    ),
                    color: customer.isActive
                        ? AppTheme.mediumGray
                        : AppTheme.successColor,
                    tooltip: customer.isActive
                        ? 'Deactivate — stop tracking renewals'
                        : 'Reactivate — put back on service',
                    onPressed: () => _toggleStatus(customer),
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

  // _buildCustomerCardList, _buildDetailsSideSheet, _mobileInfoChip,
  // _sideSheetSectionTitle, _buildDetailRow have been extracted into:
  //   • CustomerCardList       (features/customers/presentation/widgets/)
  //   • CustomerDetailsSideSheet (features/customers/presentation/widgets/)
  //   • InfoChip               (shared/widgets/info_chip.dart)
}
