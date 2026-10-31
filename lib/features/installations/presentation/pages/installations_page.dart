import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/core/utils/input_formatters.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/customers/domain/usecases/get_customers.dart';
import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/get_inventory_items.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_item_used_entity.dart';
import 'package:nasr_isp/features/installations/domain/utils/installation_aggregates.dart';
import 'package:nasr_isp/features/installations/presentation/bloc/installations_bloc.dart';
import 'package:nasr_isp/features/installations/presentation/utils/installation_item_autofill.dart';
import 'package:nasr_isp/features/installations/presentation/widgets/installation_card_list.dart';
import 'package:nasr_isp/features/installations/presentation/widgets/installation_filter_panel.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
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

  // Cached last successfully loaded state, so a transient InstallationLoading
  // or an InstallationError doesn't blank out or replace an already-visible log.
  InstallationLoaded? _lastLoaded;

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
      final employeesSnap = await FirebaseFirestore.instance
          .collection('employee_directory')
          .get();

      // Only offer active technicians for assignment — matches EmployeeModel's
      // own default (missing/null status is treated as active).
      final employees = employeesSnap.docs
          .where(
            (doc) =>
                (doc.data()['status'] as String? ?? 'active').toLowerCase() !=
                'inactive',
          )
          .map(
            (doc) => {
              'id': doc.id,
              'name': doc.data()['name'] as String? ?? 'Unnamed',
            },
          )
          .toList();

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
    context.read<InstallationBloc>().add(
      LoadInstallationsEvent(
        status: _selectedStatus,
        connectionType: _selectedConnectionType,
        employeeId: _selectedEmployeeId,
        searchQuery: _searchController.text.trim(),
      ),
    );
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

  void _showAddEditInstallationDialog(
    BuildContext context, {
    InstallationEntity? existing,
  }) {
    final formKey = GlobalKey<FormState>();
    CustomerEntity? selectedCustomer;
    final customerSearchController = TextEditingController();

    // Auto populate existing fields
    if (existing != null) {
      customerSearchController.text = existing.customerName;
      try {
        selectedCustomer = _allCustomers.firstWhere(
          (c) => c.id == existing.customerId,
        );
      } catch (_) {}
    }

    ConnectionType connectionType =
        existing?.connectionType ?? ConnectionType.wireless;
    DateTime installationDate = existing?.installationDate ?? DateTime.now();

    String? assignedEmployeeId = existing?.assignedEmployeeId;
    String? assignedEmployeeName = existing?.assignedEmployeeName;
    if (assignedEmployeeId == null && _employeesList.isNotEmpty) {
      assignedEmployeeId = _employeesList.first['id'] as String;
      assignedEmployeeName = _employeesList.first['name'] as String;
    }

    final costController = TextEditingController(
      text: existing != null
          ? existing.installationCost.toStringAsFixed(0)
          : '3000',
    );
    final remarksController = TextEditingController(
      text: existing?.remarks ?? '',
    );
    // Seeded from the stored value so an edit can never silently zero it —
    // before this field existed, saving from this dialog wiped laborCost.
    final laborCostController = TextEditingController(
      text: (existing?.laborCost ?? 0).toStringAsFixed(0),
    );

    InstallationStatus status = existing?.status ?? InstallationStatus.pending;

    // Materials Used State
    List<Map<String, dynamic>> itemsUsedState = [];
    if (existing?.itemsUsed != null) {
      for (final item in existing!.itemsUsed!) {
        itemsUsedState.add({
          'itemId': item.inventoryItemId,
          'qty': item.quantity,
          'unitCost': item.costPriceAtTime,
          'sellPrice': item.sellPriceAtTime,
        });
      }
    }

    bool isCollapsibleExpanded = itemsUsedState.isNotEmpty;
    bool isSaving = false;

    final isMobileDialog = Responsive.isMobile(context);
    final dialogTitle = existing == null
        ? 'Provision New Line Installation'
        : 'Modify Line Installation';

    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: !isMobileDialog,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final authState = context.read<AuthBloc>().state;
            final isAdmin =
                authState is AuthAuthenticated && authState.user.isAdmin;

            // Once a job is already completed, its inventory deduction has
            // already happened — further BOM edits here wouldn't adjust
            // stock, so they're locked to avoid silent inventory drift.
            final materialsLocked =
                existing != null &&
                existing.status == InstallationStatus.completed;

            // Live BOM totals, through the same MaterialTotals used by the
            // saved entity — so this preview and the record it produces
            // cannot disagree.
            final materials = MaterialTotals.fromRows(itemsUsedState);
            final totalItemsDeductQty = itemsUsedState.fold<int>(
              0,
              (acc, row) => acc + ((row['qty'] as num?)?.toInt() ?? 0),
            );

            // What the job will be worth once saved. Materials are billed on
            // top of the setup fee, so they land on both sides of the ledger.
            final previewMoney = MoneyLine(
              amountBilled:
                  (double.tryParse(costController.text.trim()) ?? 0.0) +
                  materials.revenue,
              costIncurred:
                  materials.cost +
                  (double.tryParse(laborCostController.text.trim()) ?? 0.0),
            );

            // Auto-fills the BOM with every inventory item tagged for the
            // selected connection type (or "both") the moment a connection
            // type is picked. Never runs if the job's materials are locked,
            // or if itemsUsedState already has rows — manually added/edited
            // rows (or a previous auto-fill) are never overwritten.
            void autoFillItemsForConnectionType(ConnectionType type) {
              if (materialsLocked || itemsUsedState.isNotEmpty) return;
              final matches = autoSelectInstallationItems(
                type,
                _allInventoryItems,
              );
              if (matches.isEmpty) return;
              setDialogState(() {
                itemsUsedState = matches;
                isCollapsibleExpanded = true;
              });
            }

            Future<void> submit() async {
              if (formKey.currentState!.validate()) {
                final bloc = context.read<InstallationBloc>();

                // Check if status is transitioning to Completed and has materials
                final isNewComplete =
                    existing?.status != InstallationStatus.completed &&
                    status == InstallationStatus.completed;

                if (isNewComplete && itemsUsedState.isNotEmpty) {
                  final confirmSave = await showDialog<bool>(
                    context: ctx,
                    builder: (cCtx) => AlertDialog(
                      title: const Text('Confirm Inventory Deduction'),
                      content: Text(
                        'Saving this job as Completed will immediately deduct a total of $totalItemsDeductQty item(s) from inventory. Do you wish to continue?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(cCtx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(cCtx, true),
                          child: const Text('Confirm and Deduct'),
                        ),
                      ],
                    ),
                  );
                  if (confirmSave != true) return;
                  if (!ctx.mounted || !context.mounted) return;
                }

                setDialogState(() => isSaving = true);

                // Construct List<InstallationItemUsedEntity>
                final List<InstallationItemUsedEntity> items = [];
                for (final row in itemsUsedState) {
                  final itemId = row['itemId'] as String;
                  final qty = row['qty'] as int;
                  final unitCost = row['unitCost'] as double;
                  final sellPrice = row['sellPrice'] as double;
                  final invItem = _allInventoryItems.firstWhere(
                    (i) => i.id == itemId,
                  );

                  items.add(
                    InstallationItemUsedEntity(
                      inventoryItemId: itemId,
                      itemName: invItem.name,
                      quantity: qty,
                      costPriceAtTime: unitCost,
                      sellPriceAtTime: sellPrice,
                    ),
                  );
                }

                final customer = selectedCustomer!;
                // Non-admins never see the labor field, so their saves must
                // carry the stored value through untouched rather than
                // parsing an empty controller.
                final double? enteredLabor = isAdmin
                    ? (double.tryParse(laborCostController.text.trim()) ?? 0.0)
                    : existing?.laborCost;

                final InstallationEntity updatedInstallation = existing == null
                    ? InstallationEntity(
                        id: const Uuid().v4(),
                        customerId: customer.id,
                        customerName: customer.name,
                        connectionType: connectionType,
                        installationDate: installationDate,
                        assignedEmployeeId: assignedEmployeeId,
                        assignedEmployeeName: assignedEmployeeName,
                        installationCost: double.parse(costController.text),
                        status: status,
                        remarks: remarksController.text.trim(),
                        itemsUsed: items.isEmpty ? null : items,
                        createdAt: DateTime.now(),
                        laborCost: enteredLabor,
                      )
                    // copyWith, not a fresh constructor: any field this dialog
                    // does not edit — equipmentCost, completedAt, createdAt,
                    // and anything added later — is carried over instead of
                    // being silently defaulted to null on save.
                    : existing.copyWith(
                        customerId: customer.id,
                        customerName: customer.name,
                        connectionType: connectionType,
                        installationDate: installationDate,
                        assignedEmployeeId: assignedEmployeeId,
                        assignedEmployeeName: assignedEmployeeName,
                        installationCost: double.parse(costController.text),
                        status: status,
                        remarks: remarksController.text.trim(),
                        itemsUsed:
                            items, // empty list reads as no BOM, same as null
                        laborCost: enteredLabor,
                      );

                if (!mounted || !ctx.mounted || !context.mounted) return;

                if (existing == null) {
                  bloc.add(
                    CreateInstallationEvent(
                      updatedInstallation,
                      status: _selectedStatus,
                      connectionType: _selectedConnectionType,
                      employeeId: _selectedEmployeeId,
                      searchQuery: _searchController.text.trim(),
                    ),
                  );
                } else {
                  bloc.add(
                    UpdateInstallationEvent(
                      updatedInstallation,
                      status: _selectedStatus,
                      connectionType: _selectedConnectionType,
                      employeeId: _selectedEmployeeId,
                      searchQuery: _searchController.text.trim(),
                    ),
                  );
                }

                final result = await bloc.stream.firstWhere(
                  (s) => s is InstallationLoaded || s is InstallationError,
                );

                if (!mounted || !ctx.mounted || !context.mounted) return;

                if (result is InstallationError) {
                  setDialogState(() => isSaving = false);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save: ${result.message}'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      existing == null
                          ? 'Installation logged successfully'
                          : 'Installation updated successfully',
                    ),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            }

            final connectionAndDateFields = isMobileDialog
                ? Column(
                    children: [
                      DropdownButtonFormField<ConnectionType>(
                        value: connectionType,
                        decoration: const InputDecoration(
                          labelText: 'Connection Line Type',
                        ),
                        items: ConnectionType.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => connectionType = val);
                            autoFillItemsForConnectionType(val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: installationDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (!dialogContext.mounted) return;
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
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ConnectionType>(
                          value: connectionType,
                          decoration: const InputDecoration(
                            labelText: 'Connection Line Type',
                          ),
                          items: ConnectionType.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => connectionType = val);
                              autoFillItemsForConnectionType(val);
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
                            if (!dialogContext.mounted) return;
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
                  );

            void handleStatusChange(InstallationStatus? val) {
              if (val != null) {
                // Block Cancel transition in UI if previously completed
                if (existing?.status == InstallationStatus.completed &&
                    val == InstallationStatus.cancelled) {
                  showDialog(
                    context: ctx,
                    builder: (wCtx) => AlertDialog(
                      title: const Text('Action Blocked'),
                      content: const Text(
                        'Cancelling a completed installation is not allowed directly. You must manually manage the stock reversals or log movements.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(wCtx),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                setDialogState(() => status = val);
              }
            }

            final costAndStatusFields = isMobileDialog
                ? Column(
                    children: [
                      TextFormField(
                        controller: costController,
                        decoration: const InputDecoration(
                          labelText: 'Setup Fee Billed (PKR)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: AppInputFormatters.decimal,
                        onChanged: (_) => setDialogState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Billed cost is required';
                          if (double.tryParse(v) == null)
                            return 'Enter a numeric value';
                          return null;
                        },
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: laborCostController,
                          decoration: const InputDecoration(
                            labelText: 'Technician / Labor Cost (PKR)',
                            helperText:
                                'Paid to the installer. Reduces job profit.',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: AppInputFormatters.decimal,
                          onChanged: (_) => setDialogState(() {}),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return null; // treated as 0
                            if (double.tryParse(v) == null)
                              return 'Enter a numeric value';
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<InstallationStatus>(
                        value: status,
                        decoration: const InputDecoration(
                          labelText: 'Operational Status',
                        ),
                        items: InstallationStatus.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: handleStatusChange,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: costController,
                          decoration: const InputDecoration(
                            labelText: 'Setup Fee Billed (PKR)',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: AppInputFormatters.decimal,
                          onChanged: (_) => setDialogState(() {}),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Billed cost is required';
                            if (double.tryParse(v) == null)
                              return 'Enter a numeric value';
                            return null;
                          },
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: laborCostController,
                            decoration: const InputDecoration(
                              labelText: 'Labor Cost (PKR)',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: AppInputFormatters.decimal,
                            onChanged: (_) => setDialogState(() {}),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return null; // treated as 0
                              if (double.tryParse(v) == null)
                                return 'Enter a numeric value';
                              return null;
                            },
                          ),
                        ),
                      ],
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<InstallationStatus>(
                          value: status,
                          decoration: const InputDecoration(
                            labelText: 'Operational Status',
                          ),
                          items: InstallationStatus.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: handleStatusChange,
                        ),
                      ),
                    ],
                  );

            final formContent = Column(
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
                      return customer.name.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    });
                  },
                  displayStringForOption: (CustomerEntity option) =>
                      option.name,
                  fieldViewBuilder:
                      (context, textController, focusNode, onFieldSubmitted) {
                        // Sync autocomplete text controller on creation/edit
                        if (textController.text.isEmpty &&
                            customerSearchController.text.isNotEmpty) {
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
                      if (connStr.contains('fiber') ||
                          connStr.contains('optical')) {
                        connectionType = ConnectionType.opticalFibre;
                      } else {
                        connectionType = ConnectionType.wireless;
                      }
                    });
                    autoFillItemsForConnectionType(connectionType);
                  },
                ),
                const SizedBox(height: 16),

                // Connection Type & Installation Date
                connectionAndDateFields,
                const SizedBox(height: 16),

                // Assigned Employee
                DropdownButtonFormField<String>(
                  value: assignedEmployeeId,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Installer / Technician',
                  ),
                  items: _employeesList
                      .map(
                        (emp) => DropdownMenuItem(
                          value: emp['id'] as String,
                          child: Text(emp['name'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final matched = _employeesList.firstWhere(
                        (e) => e['id'] == val,
                      );
                      setDialogState(() {
                        assignedEmployeeId = val;
                        assignedEmployeeName = matched['name'] as String;
                      });
                    }
                  },
                  validator: (v) =>
                      v == null ? 'Technician assignment required' : null,
                ),
                const SizedBox(height: 16),

                // Installation Cost & Status
                costAndStatusFields,
                const SizedBox(height: 16),

                // Remarks
                TextFormField(
                  controller: remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Job Remarks / Details',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Collapsible materials used section
                ExpansionTile(
                  initiallyExpanded: isCollapsibleExpanded,
                  title: Text(
                    materialsLocked
                        ? 'Materials Used (locked — job already completed)'
                        : 'Materials Used (optional — leave empty for historical records)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: materialsLocked
                      ? const Text(
                          'Inventory has already been deducted for this job. Adjust stock directly via the Inventory page if a correction is needed.',
                          style: TextStyle(fontSize: 11),
                        )
                      : null,
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

                        final itemDropdown = DropdownButtonFormField<String>(
                          value: selectedItemId,
                          hint: const Text('Select Material'),
                          items: _allInventoryItems
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(
                                    item.quantityInStock <= 0
                                        ? '${item.name} (0 pcs — Out of Stock)'
                                        : '${item.name} (Stock: ${item.quantityInStock} ${item.unit.isEmpty ? 'pcs' : item.unit})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: materialsLocked
                              ? null
                              : (val) {
                                  if (val != null) {
                                    final selectedItem = _allInventoryItems
                                        .firstWhere((i) => i.id == val);
                                    setDialogState(() {
                                      row['itemId'] = val;
                                      row['unitCost'] = selectedItem.unitCost;
                                      row['sellPrice'] = selectedItem.sellPrice;
                                    });
                                  }
                                },
                        );
                        final qtyField = TextFormField(
                          initialValue: row['qty'].toString(),
                          decoration: const InputDecoration(labelText: 'Qty'),
                          keyboardType: TextInputType.number,
                          inputFormatters: AppInputFormatters.integer,
                          enabled: !materialsLocked,
                          onChanged: (val) {
                            final parsed = int.tryParse(val) ?? 0;
                            setDialogState(() => row['qty'] = parsed);
                          },
                        );
                        final unitCostText = isAdmin
                            ? Text(
                                '@ ${DateTimeUtils.formatCurrency(row['unitCost'] as double)}',
                                style: const TextStyle(fontSize: 12),
                              )
                            : null;
                        final sellPriceField = isAdmin
                            ? TextFormField(
                                key: ValueKey('sellPrice_$idx'),
                                initialValue: (row['sellPrice'] as double)
                                    .toStringAsFixed(2),
                                decoration: const InputDecoration(
                                  labelText: 'Sell Price',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                enabled: !materialsLocked,
                                onChanged: (val) {
                                  final parsed = double.tryParse(val) ?? 0.0;
                                  setDialogState(
                                    () => row['sellPrice'] = parsed,
                                  );
                                },
                              )
                            : null;
                        final deleteButton = IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: AppColors.errorRed,
                          ),
                          onPressed: materialsLocked
                              ? null
                              : () {
                                  setDialogState(() {
                                    itemsUsedState.removeAt(idx);
                                  });
                                },
                        );

                        if (isMobileDialog) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                itemDropdown,
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: qtyField),
                                    if (sellPriceField != null) ...[
                                      const SizedBox(width: 8),
                                      Expanded(child: sellPriceField),
                                    ],
                                    if (unitCostText != null) ...[
                                      const SizedBox(width: 8),
                                      unitCostText,
                                    ],
                                    deleteButton,
                                  ],
                                ),
                              ],
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: itemDropdown),
                              const SizedBox(width: 8),
                              Expanded(flex: 1, child: qtyField),
                              const SizedBox(width: 8),
                              if (sellPriceField != null) ...[
                                Expanded(flex: 1, child: sellPriceField),
                                const SizedBox(width: 8),
                              ],
                              if (unitCostText != null)
                                Expanded(flex: 1, child: unitCostText),
                              deleteButton,
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: materialsLocked || _allInventoryItems.isEmpty
                          ? null
                          : () {
                              setDialogState(() {
                                itemsUsedState.add({
                                  'itemId': _allInventoryItems.first.id,
                                  'qty': 1,
                                  'unitCost': _allInventoryItems.first.unitCost,
                                  'sellPrice':
                                      _allInventoryItems.first.sellPrice,
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
                            DateTimeUtils.formatCurrency(materials.cost),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Material Margin:'),
                          Text(
                            DateTimeUtils.formatCurrency(materials.markup),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Job Profit:'),
                          Text(
                            DateTimeUtils.formatCurrency(previewMoney.profit),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: previewMoney.profit >= 0
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            );

            final saveIcon = isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 16);
            final saveLabel = Text(isSaving ? 'Saving...' : 'Save Job');

            if (isMobileDialog) {
              return Dialog.fullscreen(
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(dialogTitle),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: isSaving ? null : () => Navigator.pop(ctx),
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
                        onPressed: isSaving ? null : submit,
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
                  width: 600,
                  child: SingleChildScrollView(child: formContent),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSaving ? null : submit,
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

  void _confirmDeleteInstallation(
    BuildContext context,
    InstallationEntity inst,
  ) {
    bool isDeleting = false;
    showDialog(
      context: context,
      builder: (dCtx) {
        return StatefulBuilder(
          builder: (dCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Delete Log'),
              content: const Text(
                'Are you sure you want to permanently delete this installation log? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(dCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          final bloc = context.read<InstallationBloc>();
                          bloc.add(
                            DeleteInstallationEvent(
                              inst.id,
                              status: _selectedStatus,
                              connectionType: _selectedConnectionType,
                              employeeId: _selectedEmployeeId,
                              searchQuery: _searchController.text.trim(),
                            ),
                          );

                          final result = await bloc.stream.firstWhere(
                            (s) =>
                                s is InstallationLoaded ||
                                s is InstallationError,
                          );

                          if (!mounted || !dCtx.mounted || !context.mounted)
                            return;

                          if (result is InstallationError) {
                            setDialogState(() => isDeleting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to delete: ${result.message}',
                                ),
                                backgroundColor: AppColors.errorRed,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(dCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Installation log deleted'),
                            ),
                          );
                        },
                  child: Text(isDeleting ? 'Deleting...' : 'Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static const _accent = Color(0xFF0F766E);
  static const _ink = Color(0xFF14213D);
  static const _muted = Color(0xFF5B6472);
  static const _border = Color(0xFFE3E6EB);
  static const _line = Color(0xFFC9CED6);

  /// Rs 3,000 style, with a minus sign if negative.
  String _rs(num amount) {
    final negative = amount < 0;
    final digits = amount.abs().round().toString();
    final withCommas = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '${negative ? '-' : ''}Rs $withCommas';
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
          padding: Responsive.pagePaddingFor(Responsive.deviceTypeOf(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Installations',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'New connections: who did the job, and what it earned.',
                          style: TextStyle(fontSize: 14, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoadingDropdowns
                          ? null
                          : () => _showAddEditInstallationDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Log installation'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // ── Main Bloc Builder: summary, filters, list ────────────────
              BlocConsumer<InstallationBloc, InstallationState>(
                listener: (context, state) {
                  if (state is InstallationLoaded) {
                    _lastLoaded = state;
                  } else if (state is InstallationError &&
                      _lastLoaded != null) {
                    // Keep the existing log on screen; just surface the failure.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.errorRed,
                      ),
                    );
                  }
                },
                builder: (context, rawState) {
                  // Prefer the freshly-loaded state; otherwise fall back to
                  // the last successfully loaded log rather than blanking the
                  // page during a transient reload or a failed save/delete.
                  final state = rawState is InstallationLoaded
                      ? rawState
                      : _lastLoaded;

                  if (state == null) {
                    if (rawState is InstallationError) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.errorRed,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              rawState.message,
                              style: const TextStyle(color: AppColors.errorRed),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _triggerLoad,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    );
                  }

                  final list = state.installations;

                  // SCOPE: the money cards cover completed jobs only, within
                  // the current filters. Cancelled and pending jobs never
                  // contribute money on any screen. The list below still
                  // shows every job: it is an operations log, not a ledger.
                  final billable = list
                      .where((i) => isFinanciallyCountable(i.status))
                      .toList();
                  final totals = installationsMoney(billable);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isAdmin) ...[
                        _buildMoneyCards(totals, billable.length, list.length),
                        const SizedBox(height: 24),
                      ],

                      // Filters
                      InstallationFilterPanel(
                        searchController: _searchController,
                        selectedStatus: _selectedStatus,
                        selectedConnectionType: _selectedConnectionType,
                        selectedEmployeeId: _selectedEmployeeId,
                        employeesList: _employeesList,
                        activeFilterCount:
                            (_selectedStatus != null ? 1 : 0) +
                            (_selectedConnectionType != null ? 1 : 0) +
                            (_selectedEmployeeId != null ? 1 : 0) +
                            (_searchController.text.isNotEmpty ? 1 : 0),
                        onSearchChanged: (query) {
                          setState(() {});
                          _triggerLoad();
                        },
                        onConnectionTypeChanged: (val) {
                          setState(() => _selectedConnectionType = val);
                          _triggerLoad();
                        },
                        onEmployeeChanged: (val) {
                          setState(() => _selectedEmployeeId = val);
                          _triggerLoad();
                        },
                        onStatusChanged: (status) {
                          setState(() => _selectedStatus = status);
                          _triggerLoad();
                        },
                        onClearFilters: _clearFilters,
                      ),
                      const SizedBox(height: 16),

                      // List
                      if (list.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
                          ),
                          child: const EmptyStateWidget(
                            icon: Icons.construction_outlined,
                            title: 'No installations found',
                            subtitle:
                                'Change your filters or log a new installation to begin.',
                          ),
                        )
                      else
                        ResponsiveSwitcher(
                          mobile: InstallationCardList(
                            installations: list,
                            isAdmin: isAdmin,
                            onEdit: (inst) => _showAddEditInstallationDialog(
                              context,
                              existing: inst,
                            ),
                            onDelete: (inst) =>
                                _confirmDeleteInstallation(context, inst),
                          ),
                          desktop: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _buildInstallationsTable(list, isAdmin),
                          ),
                        ),
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

  // ── Money cards (admin only) ───────────────────────────────────────────────

  Widget _statCard(String label, String value, {String? note, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color ?? _ink,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note, style: const TextStyle(fontSize: 12, color: _muted)),
          ],
        ],
      ),
    );
  }

  Widget _buildMoneyCards(dynamic totals, int completedCount, int totalCount) {
    final cards = <Widget>[
      _statCard(
        'Billed to customers',
        _rs(totals.amountBilled),
        note:
            'Setup fees + materials · $completedCount completed of $totalCount in view',
      ),
      _statCard(
        'Material and labour cost',
        _rs(totals.costIncurred),
        note: 'Completed jobs in this view',
      ),
      _statCard(
        'Net installation profit',
        _rs(totals.profit),
        color: totals.profit >= 0 ? _accent : AppColors.errorRed,
        note: totals.marginPct != null
            ? '${totals.marginPct!.toStringAsFixed(1)}% margin · billed minus cost'
            : 'No completed jobs in this view',
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        const gap = 16.0;
        final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
        final width = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }

  // ── Table (fills the full width) ───────────────────────────────────────────

  Widget _headerCell(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: _muted,
    ),
  );

  Widget _tableRow(List<int> flex, List<Widget> cells, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEEF0F3))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flex[i],
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: cells[i],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstallationsTable(
    List<InstallationEntity> installations,
    bool isAdmin,
  ) {
    final flex = isAdmin
        ? const [17, 13, 11, 18, 9, 10, 10, 10, 14]
        : const [26, 20, 16, 26, 12];
    final minWidth = isAdmin ? 1180.0 : 700.0;

    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth < minWidth ? minWidth : c.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                _tableRow(flex, [
                  _headerCell('Customer'),
                  _headerCell('Installer'),
                  _headerCell('Date'),
                  _headerCell('Materials used'),
                  if (isAdmin) _headerCell('Cost'),
                  if (isAdmin) _headerCell('Billed'),
                  if (isAdmin) _headerCell('Profit'),
                  _headerCell('Status'),
                  if (isAdmin) _headerCell('Actions'),
                ]),
                for (var i = 0; i < installations.length; i++)
                  _installationRow(
                    flex,
                    installations[i],
                    isAdmin,
                    last: i == installations.length - 1,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _installationRow(
    List<int> flex,
    InstallationEntity inst,
    bool isAdmin, {
    required bool last,
  }) {
    // Every figure comes off the one MoneyLine, so the visible columns always
    // satisfy Billed - Cost = Profit.
    final money = inst.money;
    final statusColor = installationStatusColor(inst.status);

    String bomText = 'No items logged';
    if (inst.itemsUsed != null && inst.itemsUsed!.isNotEmpty) {
      bomText = inst.itemsUsed!
          .map((i) => '${i.itemName} (x${i.quantity})')
          .join(', ');
    }

    final profitColor = !inst.hasCostData
        ? _ink
        : (money.profit > 0
              ? AppTheme.successColor
              : (money.profit < 0 ? AppTheme.errorColor : _ink));

    return _tableRow(flex, [
      Text(
        inst.customerName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: _ink,
        ),
      ),
      Text(
        inst.assignedEmployeeName ?? 'Unassigned',
        style: const TextStyle(fontSize: 14, color: _ink),
      ),
      Text(
        DateTimeUtils.formatDate(inst.installationDate),
        style: const TextStyle(fontSize: 14, color: _ink),
      ),
      Tooltip(
        message: bomText,
        child: Text(
          bomText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: _muted,
            fontStyle: bomText == 'No items logged' ? FontStyle.italic : null,
          ),
        ),
      ),
      if (isAdmin)
        Text(
          inst.hasCostData ? _rs(money.costIncurred) : '—',
          style: const TextStyle(fontSize: 14, color: _ink),
        ),
      if (isAdmin)
        Text(
          _rs(money.amountBilled),
          style: const TextStyle(fontSize: 14, color: _ink),
        ),
      if (isAdmin)
        Tooltip(
          // A job with no logged costs still has an exact profit: it just
          // equals what was billed. Caveat it rather than hiding it.
          message: inst.hasCostData
              ? ''
              : 'No material or labour cost recorded, so profit assumes zero cost.',
          child: Text(
            _rs(money.profit),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: profitColor,
            ),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            inst.status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      ),
      if (isAdmin)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                foregroundColor: _ink,
                side: const BorderSide(color: _line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              onPressed: () =>
                  _showAddEditInstallationDialog(context, existing: inst),
              child: const Text('Edit'),
            ),
            PopupMenuButton<String>(
              tooltip: 'More actions',
              icon: const Icon(Icons.more_horiz),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onSelected: (v) {
                if (v == 'delete') _confirmDeleteInstallation(context, inst);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete log',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
          ],
        ),
    ], last: last);
  }
}
