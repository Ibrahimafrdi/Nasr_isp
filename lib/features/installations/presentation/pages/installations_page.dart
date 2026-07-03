import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/customers/domain/usecases/get_customers.dart';
import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/get_inventory_items.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_item_used_entity.dart';
import 'package:nasr_isp/features/installations/presentation/bloc/installations_bloc.dart';
import 'package:nasr_isp/shared/widgets/app_filter_widgets.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';
import 'package:nasr_isp/shared/widgets/reusable_filter_components.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/config/service_locator.dart';
import 'package:uuid/uuid.dart';

class InstallationsPage extends StatefulWidget {
  const InstallationsPage({Key? key}) : super(key: key);

  @override
  State<InstallationsPage> createState() => _InstallationsPageState();
}

class _InstallationsPageState extends State<InstallationsPage> {
  late TextEditingController _searchController;

  String? _selectedStatus; // null = "All"
  String? _selectedConnectionType; // null = "All"
  String? _selectedEmployeeId; // null = "All"

  List<CustomerEntity> _allCustomers = [];
  List<InventoryItemEntity> _allInventoryItems = [];
  List<Map<String, dynamic>> _employeesList = [];
  bool _isLoadingDropdowns = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadDropdownData();
    _triggerLoad();
  }

  Future<void> _loadDropdownData() async {
    try {
      final customers = await getIt<GetCustomers>()();
      final inventory = await getIt<GetInventoryItems>()();
      final employeesSnap = await FirebaseFirestore.instance.collection('employees').get();
      
      final employees = employeesSnap.docs.map((doc) => {
        'id': doc.id,
        'name': doc.data()['name'] as String? ?? 'Unnamed',
      }).toList();

      if (mounted) {
        setState(() {
          _allCustomers = customers;
          _allInventoryItems = inventory;
          _employeesList = employees;
          _isLoadingDropdowns = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDropdowns = false);
      }
    }
  }

  void _triggerLoad() {
    context.read<InstallationBloc>().add(LoadInstallationsEvent(
      status: _selectedStatus,
      connectionType: _selectedConnectionType,
      employeeId: _selectedEmployeeId,
      searchQuery: _searchController.text.trim(),
    ));
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
      _selectedEmployeeId = null;
    });
    _triggerLoad();
  }

  void _showAddEditInstallationDialog(BuildContext context, {InstallationEntity? existing}) {
    final formKey = GlobalKey<FormState>();
    CustomerEntity? selectedCustomer;
    final customerSearchController = TextEditingController();
    
    // Auto populate existing fields
    if (existing != null) {
      customerSearchController.text = existing.customerName;
      try {
        selectedCustomer = _allCustomers.firstWhere((c) => c.id == existing.customerId);
      } catch (_) {}
    }

    ConnectionType connectionType = existing?.connectionType ?? ConnectionType.wireless;
    DateTime installationDate = existing?.installationDate ?? DateTime.now();
    
    String? assignedEmployeeId = existing?.assignedEmployeeId;
    String? assignedEmployeeName = existing?.assignedEmployeeName;
    if (assignedEmployeeId == null && _employeesList.isNotEmpty) {
      assignedEmployeeId = _employeesList.first['id'] as String;
      assignedEmployeeName = _employeesList.first['name'] as String;
    }

    final costController = TextEditingController(
      text: existing != null ? existing.installationCost.toStringAsFixed(0) : '3000',
    );
    final remarksController = TextEditingController(text: existing?.remarks ?? '');
    
    InstallationStatus status = existing?.status ?? InstallationStatus.pending;

    // Materials Used State
    List<Map<String, dynamic>> itemsUsedState = [];
    if (existing?.itemsUsed != null) {
      for (final item in existing!.itemsUsed!) {
        itemsUsedState.add({
          'itemId': item.inventoryItemId,
          'qty': item.quantity,
          'unitCost': item.costPriceAtTime,
        });
      }
    }

    bool isCollapsibleExpanded = itemsUsedState.isNotEmpty;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final authState = context.read<AuthBloc>().state;
            final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

            // Calculate live material cost
            double materialCostTotal = 0.0;
            int totalItemsDeductQty = 0;
            for (final row in itemsUsedState) {
              final qty = row['qty'] as int;
              final unitCost = row['unitCost'] as double;
              materialCostTotal += qty * unitCost;
              totalItemsDeductQty += qty;
            }

            return AlertDialog(
              title: Text(existing == null ? 'Provision New Line Installation' : 'Modify Line Installation'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 600,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Searchable Customer Selector (using Autocomplete)
                        Autocomplete<CustomerEntity>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return _allCustomers;
                            }
                            return _allCustomers.where((CustomerEntity customer) {
                              return customer.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          displayStringForOption: (CustomerEntity option) => option.name,
                          fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                            // Sync autocomplete text controller on creation/edit
                            if (textController.text.isEmpty && customerSearchController.text.isNotEmpty) {
                              textController.text = customerSearchController.text;
                            }
                            return TextFormField(
                              controller: textController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Search Subscriber Account / Name',
                                suffixIcon: Icon(Icons.search, size: 18),
                              ),
                              validator: (v) {
                                if (selectedCustomer == null) {
                                  return 'Please select a valid subscriber from the dropdown options';
                                }
                                return null;
                              },
                            );
                          },
                          onSelected: (CustomerEntity selection) {
                            setDialogState(() {
                              selectedCustomer = selection;
                              customerSearchController.text = selection.name;
                              
                              // Auto fill connection type
                              final connStr = selection.connectionType.toLowerCase();
                              if (connStr.contains('fiber') || connStr.contains('optical')) {
                                connectionType = ConnectionType.opticalFibre;
                              } else {
                                connectionType = ConnectionType.wireless;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Connection Type & Installation Date
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<ConnectionType>(
                                value: connectionType,
                                decoration: const InputDecoration(labelText: 'Connection Line Type'),
                                items: ConnectionType.values.map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.displayName),
                                )).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => connectionType = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: dialogContext,
                                    initialDate: installationDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => installationDate = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Installation Date',
                                    suffixIcon: Icon(Icons.calendar_today, size: 16),
                                  ),
                                  child: Text(
                                    '${installationDate.day}/${installationDate.month}/${installationDate.year}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Assigned Employee
                        DropdownButtonFormField<String>(
                          value: assignedEmployeeId,
                          decoration: const InputDecoration(labelText: 'Assigned Installer / Technician'),
                          items: _employeesList.map((emp) => DropdownMenuItem(
                            value: emp['id'] as String,
                            child: Text(emp['name'] as String),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final matched = _employeesList.firstWhere((e) => e['id'] == val);
                              setDialogState(() {
                                assignedEmployeeId = val;
                                assignedEmployeeName = matched['name'] as String;
                              });
                            }
                          },
                          validator: (v) => v == null ? 'Technician assignment required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Installation Cost & Status
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: costController,
                                decoration: const InputDecoration(
                                  labelText: 'Setup Fee Billed (PKR)',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Billed cost is required';
                                  if (double.tryParse(v) == null) return 'Enter a numeric value';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<InstallationStatus>(
                                value: status,
                                decoration: const InputDecoration(labelText: 'Operational Status'),
                                items: InstallationStatus.values.map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.displayName),
                                )).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    // Block Cancel transition in UI if previously completed
                                    if (existing?.status == InstallationStatus.completed && val == InstallationStatus.cancelled) {
                                      showDialog(
                                        context: ctx,
                                        builder: (wCtx) => AlertDialog(
                                          title: const Text('Action Blocked'),
                                          content: const Text('Cancelling a completed installation is not allowed directly. You must manually manage the stock reversals or log movements.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(wCtx),
                                              child: const Text('OK'),
                                            )
                                          ],
                                        ),
                                      );
                                      return;
                                    }
                                    setDialogState(() => status = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Remarks
                        TextFormField(
                          controller: remarksController,
                          decoration: const InputDecoration(labelText: 'Job Remarks / Details'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // Collapsible materials used section
                        ExpansionTile(
                          initiallyExpanded: isCollapsibleExpanded,
                          title: const Text(
                            'Materials Used (optional — leave empty for historical records)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          onExpansionChanged: (exp) {
                            setDialogState(() => isCollapsibleExpanded = exp);
                          },
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: itemsUsedState.length,
                              itemBuilder: (rowCtx, idx) {
                                final row = itemsUsedState[idx];
                                String? selectedItemId = row['itemId'] as String?;
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      // Item Dropdown
                                      Expanded(
                                        flex: 3,
                                        child: DropdownButtonFormField<String>(
                                          value: selectedItemId,
                                          hint: const Text('Select Material'),
                                          items: _allInventoryItems.map((item) => DropdownMenuItem(
                                            value: item.id,
                                            child: Text('${item.name} (Stock: ${item.quantityInStock})'),
                                          )).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              final selectedItem = _allInventoryItems.firstWhere((i) => i.id == val);
                                              setDialogState(() {
                                                row['itemId'] = val;
                                                row['unitCost'] = selectedItem.unitCost;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Quantity
                                      Expanded(
                                        flex: 1,
                                        child: TextFormField(
                                          initialValue: row['qty'].toString(),
                                          decoration: const InputDecoration(labelText: 'Qty'),
                                          keyboardType: TextInputType.number,
                                          onChanged: (val) {
                                            final parsed = int.tryParse(val) ?? 0;
                                            setDialogState(() => row['qty'] = parsed);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Unit Cost (Admin only)
                                      if (isAdmin)
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            '@ ${DateTimeUtils.formatCurrency(row['unitCost'] as double)}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),

                                      // Remove button
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.errorRed),
                                        onPressed: () {
                                          setDialogState(() {
                                            itemsUsedState.removeAt(idx);
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                if (_allInventoryItems.isEmpty) return;
                                setDialogState(() {
                                  itemsUsedState.add({
                                    'itemId': _allInventoryItems.first.id,
                                    'qty': 1,
                                    'unitCost': _allInventoryItems.first.unitCost,
                                  });
                                });
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Row'),
                            ),
                            if (isAdmin && itemsUsedState.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Estimated Material Cost:'),
                                  Text(
                                    DateTimeUtils.formatCurrency(materialCostTotal),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            // Check if status is transitioning to Completed and has materials
                            final isNewComplete = existing?.status != InstallationStatus.completed &&
                                status == InstallationStatus.completed;

                            if (isNewComplete && itemsUsedState.isNotEmpty) {
                              final confirmSave = await showDialog<bool>(
                                context: ctx,
                                builder: (cCtx) => AlertDialog(
                                  title: const Text('Confirm Inventory Deduction'),
                                  content: Text('Saving this job as Completed will immediately deduct a total of $totalItemsDeductQty item(s) from inventory. Do you wish to continue?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(cCtx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(cCtx, true),
                                      child: const Text('Confirm and Deduct'),
                                    )
                                  ],
                                ),
                              );
                              if (confirmSave != true) return;
                            }

                            setDialogState(() => isSaving = true);

                            // Construct List<InstallationItemUsedEntity>
                            final List<InstallationItemUsedEntity> items = [];
                            for (final row in itemsUsedState) {
                              final itemId = row['itemId'] as String;
                              final qty = row['qty'] as int;
                              final unitCost = row['unitCost'] as double;
                              final invItem = _allInventoryItems.firstWhere((i) => i.id == itemId);

                              items.add(InstallationItemUsedEntity(
                                inventoryItemId: itemId,
                                itemName: invItem.name,
                                quantity: qty,
                                costPriceAtTime: unitCost,
                              ));
                            }

                            final customer = selectedCustomer!;
                            final updatedInstallation = InstallationEntity(
                              id: existing?.id ?? const Uuid().v4(),
                              customerId: customer.id,
                              customerName: customer.name,
                              connectionType: connectionType,
                              installationDate: installationDate,
                              assignedEmployeeId: assignedEmployeeId,
                              assignedEmployeeName: assignedEmployeeName,
                              installationCost: double.parse(costController.text),
                              status: status,
                              remarks: remarksController.text,
                              itemsUsed: items.isEmpty ? null : items,
                              createdAt: existing?.createdAt ?? DateTime.now(),
                              completedAt: existing?.completedAt,
                            );

                            if (!mounted) return;

                            if (existing == null) {
                              context.read<InstallationBloc>().add(CreateInstallationEvent(updatedInstallation));
                            } else {
                              context.read<InstallationBloc>().add(UpdateInstallationEvent(updatedInstallation));
                            }

                            Navigator.pop(ctx);
                            _triggerLoad();
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: Text(isSaving ? 'Saving...' : 'Save Job'),
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
          return const Center(child: Text('Not authenticated'));
        }

        final isAdmin = authState.user.isAdmin;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Breadcrumb(
                    items: [
                      BreadcrumbItem(
                        label: 'Home',
                        onTap: () => context.go(RoutePaths.dashboard),
                      ),
                      BreadcrumbItem(label: 'Installations'),
                    ],
                  ),
                  if (isAdmin)
                    ElevatedButton.icon(
                      onPressed: _isLoadingDropdowns
                          ? null
                          : () => _showAddEditInstallationDialog(context),
                      icon: const Icon(Icons.construction, size: 18),
                      label: const Text('Log Installation'),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Search & Filter Panel
              _buildFilterPanel(),
              const SizedBox(height: 24),

              // Main Bloc Builder for logs
              BlocConsumer<InstallationBloc, InstallationState>(
                listener: (context, state) {
                  if (state is InstallationError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.errorRed,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is InstallationLoading) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      ),
                    );
                  }

                  if (state is InstallationLoaded) {
                    final list = state.installations;

                    double totalFee = list.fold(0.0, (s, i) => s + i.installationCost);
                    
                    double totalCost = 0.0;
                    for (final inst in list) {
                      totalCost += inst.materialCost ?? 0.0;
                    }
                    double netMargin = totalFee - totalCost;

                    return Column(
                      children: [
                        // Metric cards (Admin only)
                        if (isAdmin) ...[
                          Row(
                            children: [
                              Expanded(
                                child: DashboardCard(
                                  label: 'Gross Installation Fees',
                                  value: DateTimeUtils.formatCurrency(totalFee),
                                  icon: Icons.payments,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DashboardCard(
                                  label: 'Total Material & Cable Costs',
                                  value: DateTimeUtils.formatCurrency(totalCost),
                                  icon: Icons.shopping_bag_outlined,
                                  backgroundColor: AppTheme.errorColor.withOpacity(0.04),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DashboardCard(
                                  label: 'Net Installation Profit',
                                  value: DateTimeUtils.formatCurrency(netMargin),
                                  icon: Icons.account_balance_wallet,
                                  backgroundColor: AppTheme.successColor.withOpacity(0.05),
                                  subtitle: totalFee > 0
                                      ? '${((netMargin / totalFee) * 100).toStringAsFixed(1)}% profit margin'
                                      : 'No revenue records',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Data Table
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Installation Operations Log',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                list.isEmpty
                                    ? const EmptyStateWidget(
                                        icon: Icons.construction_outlined,
                                        title: 'No Installations Found',
                                        subtitle: 'Adjust your filters or log a new installation to begin.',
                                      )
                                    : _buildInstallationsTable(list, isAdmin),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: EmptyStateWidget(
                        icon: Icons.construction_outlined,
                        title: 'Ready to load logs',
                        subtitle: 'Log list will appear here once loaded.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterPanel() {
    return AppFilterContainer(
      title: 'Search & Filter Installations',
      titleIcon: Icons.construction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterPanelHeader(
            searchController: _searchController,
            onSearchChanged: (query) => _triggerLoad(),
            onClearFilters: _clearFilters,
            activeFilterCount: (_selectedStatus != null ? 1 : 0) +
                (_selectedConnectionType != null ? 1 : 0) +
                (_selectedEmployeeId != null ? 1 : 0) +
                (_searchController.text.isNotEmpty ? 1 : 0),
            title: 'Filters',
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              // Connection Type Dropdown Filter
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedConnectionType,
                  decoration: const InputDecoration(labelText: 'Connection Line'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Connections')),
                    ...ConnectionType.values.map((t) => DropdownMenuItem(
                          value: t.name,
                          child: Text(t.displayName),
                        ))
                  ],
                  onChanged: (val) {
                    setState(() => _selectedConnectionType = val);
                    _triggerLoad();
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Assigned Employee Dropdown Filter
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedEmployeeId,
                  decoration: const InputDecoration(labelText: 'Technician Filter'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Technicians')),
                    ..._employeesList.map((e) => DropdownMenuItem(
                          value: e['id'] as String,
                          child: Text(e['name'] as String),
                        ))
                  ],
                  onChanged: (val) {
                    setState(() => _selectedEmployeeId = val);
                    _triggerLoad();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Installation Status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppStatusChipGroup(
            options: const ['pending', 'inProgress', 'completed', 'cancelled'],
            selected: _selectedStatus,
            onChanged: (status) {
              setState(() => _selectedStatus = status);
              _triggerLoad();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationsTable(List<InstallationEntity> installations, bool isAdmin) {
    return DataTableWrapper(
      columns: [
        const DataColumn(label: Text('Customer')),
        const DataColumn(label: Text('Assigned Installer')),
        const DataColumn(label: Text('Date Installed')),
        const DataColumn(label: Text('Materials Used (BOM)')),
        if (isAdmin) ...[
          const DataColumn(label: Text('Material Cost')),
          const DataColumn(label: Text('Setup Fee Charged')),
          const DataColumn(label: Text('Net Return')),
        ],
        const DataColumn(label: Text('Status')),
        if (isAdmin) const DataColumn(label: Text('Actions')),
      ],
      rows: installations.map((inst) {
        final double cost = inst.materialCost ?? 0.0;
        final double fee = inst.installationCost;
        final double profit = inst.profit ?? 0.0;

        // Construct BOM text
        String bomText = 'No items logged';
        if (inst.itemsUsed != null && inst.itemsUsed!.isNotEmpty) {
          bomText = inst.itemsUsed!.map((i) => '${i.itemName} (x${i.quantity})').join(', ');
        }

        return DataRow(
          cells: [
            DataCell(
              Text(
                inst.customerName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            DataCell(Text(inst.assignedEmployeeName ?? 'Unassigned')),
            DataCell(Text(DateTimeUtils.formatDate(inst.installationDate))),
            DataCell(
              Tooltip(
                message: bomText,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    bomText,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
            if (isAdmin) ...[
              DataCell(Text(inst.materialCost == null ? 'N/A' : DateTimeUtils.formatCurrency(cost))),
              DataCell(Text(DateTimeUtils.formatCurrency(fee))),
              DataCell(
                Text(
                  inst.profit == null ? 'N/A' : DateTimeUtils.formatCurrency(profit),
                  style: TextStyle(
                    color: profit > 0
                        ? AppTheme.successColor
                        : (profit < 0 ? AppTheme.errorColor : AppColors.charcoal),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(inst.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  inst.status.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(inst.status),
                  ),
                ),
              ),
            ),
            if (isAdmin)
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16, color: AppColors.primaryBlue),
                      onPressed: () => _showAddEditInstallationDialog(context, existing: inst),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 16, color: AppColors.errorRed),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('Delete Log'),
                            content: const Text('Are you sure you want to permanently delete this installation log? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
                                onPressed: () {
                                  context.read<InstallationBloc>().add(DeleteInstallationEvent(
                                    inst.id,
                                    status: _selectedStatus,
                                    connectionType: _selectedConnectionType,
                                    employeeId: _selectedEmployeeId,
                                    searchQuery: _searchController.text.trim(),
                                  ));
                                  Navigator.pop(dCtx);
                                },
                                child: const Text('Delete'),
                              )
                            ],
                          ),
                        );
                      },
                    )
                  ],
                ),
              ),
          ],
        );
      }).toList(),
    );
  }

  Color _getStatusColor(InstallationStatus status) {
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
