import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/features/customers/presentation/widgets/customer_card_list.dart';
import 'package:nasr_isp/features/customers/presentation/widgets/customer_details_side_sheet.dart';
import 'package:nasr_isp/features/customers/presentation/widgets/customer_filter_panel.dart';
import 'package:nasr_isp/features/customers/presentation/widgets/customer_status_dialogs.dart';
import 'package:nasr_isp/features/customers/presentation/widgets/customer_summary_tiles.dart';
import 'package:nasr_isp/features/customers/presentation/widgets/customer_table.dart';
import 'package:nasr_isp/features/customers/presentation/widgets/renew_subscription_dialog.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_bloc.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_state.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_event.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({Key? key}) : super(key: key);

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

// Colours for the redesigned screen, private to this file.
const Color _kPageBg = Color(0xFFF6F7F9);
const Color _kInk = Color(0xFF14213D);
const Color _kMuted = Color(0xFF5B6472);
const Color _kTeal = Color(0xFF0F766E);

class _CustomersPageState extends State<CustomersPage> {
  late TextEditingController _searchController;
  String? _selectedStatus;
  String? _selectedConnectionType; // null = All, 'wireless', 'fiber'
  // Counts across all customers. Kept here so the chips do not flash to zero
  // while the list is reloading.
  CustomersSummary _summary = CustomersSummary.empty;
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
            if (state is CustomersLoaded) _summary = state.summary;

            return ColoredBox(
              color: _kPageBg,
              child: SingleChildScrollView(
                padding: Responsive.pagePaddingFor(
                  Responsive.deviceTypeOf(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),

                    // Counts double as the status filter: tap a tile to
                    // filter, tap it again to clear.
                    CustomerSummaryTiles(
                      summary: _summary,
                      selectedStatus: _selectedStatus,
                      onStatusChanged: _onStatusChanged,
                    ),
                    const SizedBox(height: 16),

                    // Search and connection type.
                    CustomerFilterPanel(
                      searchController: _searchController,
                      selectedConnectionType: _selectedConnectionType,
                      activeFilterCount:
                          (_selectedStatus != null ? 1 : 0) +
                          (_searchController.text.isNotEmpty ? 1 : 0) +
                          (_selectedConnectionType != null ? 1 : 0),
                      onSearchChanged: _onSearchChanged,
                      onConnectionTypeChanged: _onConnectionTypeChanged,
                      onClearFilters: _clearFilters,
                    ),
                    const SizedBox(height: 16),

                    // Main directory table
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
                              : ResponsiveSwitcher(
                                  mobile: CustomerCardList(
                                    customers: state.customers,
                                    currentUser: authState.user,
                                    getPackageName: _getPackageName,
                                    onDelete: _confirmDelete,
                                    onRenew: _renew,
                                    onToggleStatus: _toggleStatus,
                                  ),
                                  desktop: CustomerTable(
                                    customers: state.customers,
                                    isAdmin: authState.user.isAdmin,
                                    getPackageName: _getPackageName,
                                    footerText:
                                        'Showing ${state.summary.showingFrom}-${state.summary.showingTo} of ${state.summary.filteredTotal} customers',
                                    onView: (c) =>
                                        _showDetails(c, authState.user.isAdmin),
                                    onRenew: _renew,
                                    onEdit: (c) => context.go(
                                      '${RoutePaths.customers}/${c.id}/edit',
                                    ),
                                    onToggleStatus: _toggleStatus,
                                    onDelete: _confirmDelete,
                                  ),
                                ),
                          if (state.totalPages > 1) ...[
                            const SizedBox(height: 16),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customers',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Who is on service, who needs to renew, and what they owe.',
                style: TextStyle(fontSize: 14, color: _kMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => context.go(RoutePaths.addCustomer),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add customer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kTeal,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  /// Opens the details as a panel on the right, over the page, so the table
  /// keeps the full width. Every action closes the panel first, because the
  /// reload that follows would leave it showing old data.
  void _showDetails(CustomerModel customer, bool isAdmin) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close details',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            elevation: 8,
            child: SizedBox(
              height: double.infinity,
              child: SingleChildScrollView(
                child: CustomerDetailsSideSheet(
                  customer: customer,
                  isAdmin: isAdmin,
                  getPackageName: _getPackageName,
                  onClose: () => Navigator.of(dialogContext).pop(),
                  onDelete: (c) {
                    Navigator.of(dialogContext).pop();
                    _confirmDelete(c);
                  },
                  onRenew: (c) {
                    Navigator.of(dialogContext).pop();
                    _renew(c);
                  },
                  onToggleStatus: (c) {
                    Navigator.of(dialogContext).pop();
                    _toggleStatus(c);
                  },
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
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
    final changed = await showCustomerStatusDialog(context, customer: customer);
    if (!changed || !mounted) return;
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
}
