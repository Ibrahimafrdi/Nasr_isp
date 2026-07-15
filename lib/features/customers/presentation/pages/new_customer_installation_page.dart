import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:nasr_isp/config/service_locator.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/features/employees/domain/entities/employee_entity.dart';
import 'package:nasr_isp/features/employees/presentation/bloc/employees_bloc.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_item_used_entity.dart';
import 'package:nasr_isp/features/installations/presentation/bloc/installations_bloc.dart';
import 'package:nasr_isp/features/installations/presentation/utils/installation_item_autofill.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/get_inventory_items.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_bloc.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_event.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_state.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

/// Onboards a brand-new subscriber together with their installation record
/// in a single form — contact & plan details (same fields as the standard
/// Add Customer form) plus installation date/type, cost, labor and profit.
///
/// This does NOT touch [AddCustomerPage] / the "Existing Customer" flow —
/// it is an entirely separate, additive entry point.
class NewCustomerInstallationPage extends StatefulWidget {
  const NewCustomerInstallationPage({super.key});

  @override
  State<NewCustomerInstallationPage> createState() =>
      _NewCustomerInstallationPageState();
}

class _NewCustomerInstallationPageState
    extends State<NewCustomerInstallationPage> {
  final _formKey = GlobalKey<FormState>();

  // Customer fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _addressController = TextEditingController();
  final _monthlyBillController = TextEditingController();
  final _notesController = TextEditingController();

  // Installation fields
  final _installationChargesController = TextEditingController();
  final _laborCostController = TextEditingController(text: '0');
  final _installationRemarksController = TextEditingController();

  ConnectionType _connectionType = ConnectionType.wireless;
  String? _selectedPackageId;
  DateTime _joinDate = DateTime.now();
  DateTime _installationDate = DateTime.now();
  String? _assignedEmployeeId;
  String? _assignedEmployeeName;

  // Materials Used (BOM) state — same row shape ('itemId'/'qty'/'unitCost')
  // and auto-select behavior as the standalone Add Installation form.
  List<InstallationItemRow> _itemsUsedState = [];
  List<InventoryItemEntity> _allInventoryItems = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    context.read<EmployeeBloc>().add(const LoadEmployeesEvent());
    context.read<PackagesBloc>().add(const LoadPackagesEvent());
    _installationChargesController.addListener(_recomputePreview);
    _laborCostController.addListener(_recomputePreview);
    _loadInventoryItems();
  }

  Future<void> _loadInventoryItems() async {
    try {
      final items = await getIt<GetInventoryItems>()();
      if (mounted) {
        setState(() => _allInventoryItems = items);
      }
    } catch (_) {
      // Manual "Add Item" and auto-fill simply have nothing to offer;
      // the rest of the form remains usable.
    }
  }

  void _autoFillItemsForConnectionType(ConnectionType type) {
    if (_itemsUsedState.isNotEmpty) return;
    final matches = autoSelectInstallationItems(type, _allInventoryItems);
    if (matches.isEmpty) return;
    setState(() => _itemsUsedState = matches);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _addressController.dispose();
    _monthlyBillController.dispose();
    _notesController.dispose();
    _installationChargesController.dispose();
    _laborCostController.dispose();
    _installationRemarksController.dispose();
    super.dispose();
  }

  void _recomputePreview() => setState(() {});

  double get _previewCharges =>
      double.tryParse(_installationChargesController.text.trim()) ?? 0.0;
  // Mirrors InstallationEntity.materialCost/materialRevenue: sum of the
  // Materials Used BOM rows' cost/sell price snapshots.
  double get _previewMaterialCost => _itemsUsedState.fold<double>(
      0.0, (sum, row) => sum + (row['qty'] as int) * (row['unitCost'] as double));
  double get _previewMaterialRevenue => _itemsUsedState.fold<double>(
      0.0, (sum, row) => sum + (row['qty'] as int) * (row['sellPrice'] as double));
  double get _previewLabor =>
      double.tryParse(_laborCostController.text.trim()) ?? 0.0;
  // Mirrors InstallationEntity.profit exactly.
  double get _previewProfit =>
      _previewCharges - _previewMaterialCost - _previewLabor + _previewMaterialRevenue;

  void _onPackageChanged(String? packageId, List<PackageEntity> packages) {
    if (packageId == null) return;
    final pkg = packages.firstWhere((p) => p.id == packageId);
    setState(() {
      _selectedPackageId = packageId;
      _monthlyBillController.text = pkg.price.toString();
    });
  }

  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 700;

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final nextDueDate = DateTime(_joinDate.year, _joinDate.month + 1, _joinDate.day);
    final customerId = const Uuid().v4();

    final newCustomer = CustomerModel(
      id: customerId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      cnic: _cnicController.text.trim(),
      address: _addressController.text.trim(),
      connectionType:
          _connectionType == ConnectionType.opticalFibre ? 'fiber' : 'wireless',
      packageId: _selectedPackageId,
      monthlyBill: double.tryParse(_monthlyBillController.text.trim()) ?? 0.0,
      status: 'active',
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
      joinDate: _joinDate,
      nextDueDate: nextDueDate,
    );

    final customersBloc = context.read<CustomersBloc>();
    customersBloc.add(CreateCustomerEvent(newCustomer));

    // The installation-completed sync (customer.status/installationCost)
    // reads the customer doc in a transaction, so it must exist first.
    final customerResult = await customersBloc.stream.firstWhere(
      (s) => s is CustomersLoaded || s is CustomersError,
    );

    if (!mounted) return;

    if (customerResult is CustomersError) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create customer: ${customerResult.message}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final itemsUsed = <InstallationItemUsedEntity>[
      for (final row in _itemsUsedState)
        InstallationItemUsedEntity(
          inventoryItemId: row['itemId'] as String,
          itemName: _allInventoryItems
              .firstWhere((i) => i.id == row['itemId'])
              .name,
          quantity: row['qty'] as int,
          costPriceAtTime: row['unitCost'] as double,
          sellPriceAtTime: row['sellPrice'] as double,
        ),
    ];

    final installation = InstallationEntity(
      id: const Uuid().v4(),
      customerId: customerId,
      customerName: newCustomer.name,
      connectionType: _connectionType,
      installationDate: _installationDate,
      assignedEmployeeId: _assignedEmployeeId,
      assignedEmployeeName: _assignedEmployeeName,
      installationCost: _previewCharges,
      status: InstallationStatus.completed,
      remarks: _installationRemarksController.text.trim().isEmpty
          ? null
          : _installationRemarksController.text.trim(),
      itemsUsed: itemsUsed.isEmpty ? null : itemsUsed,
      createdAt: DateTime.now(),
      laborCost: _previewLabor,
    );

    final installationBloc = context.read<InstallationBloc>();
    installationBloc.add(CreateInstallationEvent(installation));

    final installationResult = await installationBloc.stream.firstWhere(
      (s) => s is InstallationLoaded || s is InstallationError,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (installationResult is InstallationError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Customer created, but installation failed: ${installationResult.message}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New customer and installation registered successfully!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
    context.go(RoutePaths.customers);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: Text('Not authenticated')));
        }

        return BlocBuilder<PackagesBloc, PackagesState>(
          builder: (context, packagesState) {
            final availablePackages =
                packagesState is PackagesLoaded ? packagesState.packages : <PackageEntity>[];

            return BlocBuilder<EmployeeBloc, EmployeeState>(
              builder: (context, employeeState) {
                final employees = employeeState is EmployeeLoaded
                    ? employeeState.employees
                        .where((e) => e.status == EmployeeStatus.active)
                        .toList()
                    : <EmployeeEntity>[];

                return Scaffold(
                  body: SingleChildScrollView(
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
                            BreadcrumbItem(
                              label: 'Add Customer',
                              onTap: () => context.go(RoutePaths.addCustomer),
                            ),
                            BreadcrumbItem(label: 'New Customer'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'New Customer & Installation',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _sectionHeader(context, 'Account Information'),
                                      const Divider(height: 24),
                                      _responsiveRow(context, [
                                        AppFormField(
                                          label: 'Full Name',
                                          isRequired: true,
                                          controller: _nameController,
                                          validator: (v) => (v == null || v.trim().isEmpty)
                                              ? 'Required'
                                              : null,
                                        ),
                                        AppFormField(
                                          label: 'Phone Number',
                                          isRequired: true,
                                          controller: _phoneController,
                                          validator: (v) => (v == null || v.trim().isEmpty)
                                              ? 'Required'
                                              : null,
                                        ),
                                      ]),
                                      const SizedBox(height: 16),
                                      AppFormField(
                                        label: 'CNIC / National ID',
                                        isRequired: true,
                                        controller: _cnicController,
                                        validator: (v) => (v == null || v.trim().isEmpty)
                                            ? 'Required'
                                            : null,
                                      ),
                                      const SizedBox(height: 16),
                                      AppFormField(
                                        label: 'Installation Physical Address',
                                        controller: _addressController,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 16),
                                      AppFormField(
                                        label: 'Notes / Remarks',
                                        controller: _notesController,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 16),
                                      _datePickerTile(
                                        context,
                                        label: 'Join Date',
                                        value: _joinDate,
                                        onPicked: (picked) => setState(() {
                                          _joinDate = picked;
                                        }),
                                      ),
                                      const SizedBox(height: 30),

                                      _sectionHeader(context, 'Plan & Pricing Details'),
                                      const Divider(height: 24),
                                      _responsiveRow(context, [
                                        DropdownButtonFormField<ConnectionType>(
                                          initialValue: _connectionType,
                                          decoration: const InputDecoration(
                                            labelText: 'Connection / Installation Type',
                                          ),
                                          items: ConnectionType.values
                                              .map((t) => DropdownMenuItem(
                                                    value: t,
                                                    child: Text(t.displayName),
                                                  ))
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _connectionType = val);
                                              _autoFillItemsForConnectionType(val);
                                            }
                                          },
                                        ),
                                        DropdownButtonFormField<String>(
                                          initialValue: _selectedPackageId,
                                          decoration: const InputDecoration(
                                            labelText: 'Select Package',
                                          ),
                                          items: availablePackages
                                              .map((pkg) => DropdownMenuItem(
                                                    value: pkg.id,
                                                    child: Text(pkg.name),
                                                  ))
                                              .toList(),
                                          onChanged: (val) =>
                                              _onPackageChanged(val, availablePackages),
                                        ),
                                      ]),
                                      const SizedBox(height: 16),
                                      AppFormField(
                                        label: 'Monthly Bill Rate (PKR)',
                                        isRequired: true,
                                        controller: _monthlyBillController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(decimal: true),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) return 'Required';
                                          return double.tryParse(v.trim()) == null
                                              ? 'Enter a valid number'
                                              : null;
                                        },
                                      ),
                                      const SizedBox(height: 30),

                                      _sectionHeader(context, 'Installation Details'),
                                      const Divider(height: 24),
                                      _datePickerTile(
                                        context,
                                        label: 'Installation Date',
                                        value: _installationDate,
                                        onPicked: (picked) => setState(() {
                                          _installationDate = picked;
                                        }),
                                      ),
                                      const SizedBox(height: 16),
                                      DropdownButtonFormField<String>(
                                        initialValue: _assignedEmployeeId,
                                        decoration: const InputDecoration(
                                          labelText: 'Assigned Technician (Optional)',
                                        ),
                                        items: employees
                                            .map((e) => DropdownMenuItem(
                                                  value: e.id,
                                                  child: Text(e.name),
                                                ))
                                            .toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _assignedEmployeeId = val;
                                            _assignedEmployeeName = val == null
                                                ? null
                                                : employees
                                                    .firstWhere((e) => e.id == val)
                                                    .name;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      AppFormField(
                                        label: 'Installation Charges (PKR)',
                                        hintText: 'Fee billed to the customer',
                                        isRequired: true,
                                        controller: _installationChargesController,
                                        keyboardType: const TextInputType.numberWithOptions(
                                            decimal: true),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) return 'Required';
                                          return double.tryParse(v.trim()) == null
                                              ? 'Enter a valid number'
                                              : null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _materialsUsedSection(),
                                      const SizedBox(height: 16),
                                      AppFormField(
                                        label: 'Technician / Labor Cost (PKR)',
                                        controller: _laborCostController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(decimal: true),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) return null;
                                          return double.tryParse(v.trim()) == null
                                              ? 'Enter a valid number'
                                              : null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      AppFormField(
                                        label: 'Installation Notes / Remarks',
                                        controller: _installationRemarksController,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 20),
                                      _profitPreviewCard(),
                                      const SizedBox(height: 30),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton(
                                            onPressed: _isSaving
                                                ? null
                                                : () => context.go(RoutePaths.customers),
                                            child: const Text('Cancel'),
                                          ),
                                          const SizedBox(width: 16),
                                          ElevatedButton.icon(
                                            onPressed: _isSaving ? null : _saveForm,
                                            icon: const Icon(Icons.save),
                                            label: Text(_isSaving
                                                ? 'Saving...'
                                                : 'Create Customer & Installation'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _responsiveRow(BuildContext context, List<Widget> children) {
    if (_isMobile(context)) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      );
    }
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  Widget _materialsUsedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Materials Used (optional — auto-filled from inventory for the '
          'selected connection type)',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _itemsUsedState.length,
          itemBuilder: (context, idx) {
            final row = _itemsUsedState[idx];

            final itemDropdown = DropdownButtonFormField<String>(
              initialValue: row['itemId'] as String?,
              hint: const Text('Select Material'),
              items: _allInventoryItems
                  .map((item) => DropdownMenuItem(
                        value: item.id,
                        child: Text('${item.name} (Stock: ${item.quantityInStock})'),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                final selected = _allInventoryItems.firstWhere((i) => i.id == val);
                setState(() {
                  row['itemId'] = val;
                  row['unitCost'] = selected.unitCost;
                  row['sellPrice'] = selected.sellPrice;
                });
              },
            );
            final qtyField = TextFormField(
              initialValue: row['qty'].toString(),
              decoration: const InputDecoration(labelText: 'Qty'),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final parsed = int.tryParse(val) ?? 0;
                setState(() => row['qty'] = parsed);
              },
            );
            final unitCostText = Text(
              '@ ${DateTimeUtils.formatCurrency(row['unitCost'] as double)} '
              '/ sell ${DateTimeUtils.formatCurrency(row['sellPrice'] as double)}',
              style: const TextStyle(fontSize: 12),
            );
            final deleteButton = IconButton(
              icon: const Icon(Icons.delete, color: AppColors.errorRed),
              onPressed: () => setState(() => _itemsUsedState.removeAt(idx)),
            );

            if (_isMobile(context)) {
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
                        const SizedBox(width: 8),
                        unitCostText,
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
                  Expanded(flex: 1, child: unitCostText),
                  deleteButton,
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _allInventoryItems.isEmpty
              ? null
              : () {
                  setState(() {
                    _itemsUsedState.add({
                      'itemId': _allInventoryItems.first.id,
                      'qty': 1,
                      'unitCost': _allInventoryItems.first.unitCost,
                      'sellPrice': _allInventoryItems.first.sellPrice,
                    });
                  });
                },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Item'),
        ),
        if (_itemsUsedState.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Material Cost:'),
              Text(
                DateTimeUtils.formatCurrency(_previewMaterialCost),
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
                DateTimeUtils.formatCurrency(_previewMaterialRevenue - _previewMaterialCost),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _datePickerTile(
    BuildContext context, {
    required String label,
    required DateTime value,
    required void Function(DateTime) onPicked,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        DateTimeUtils.formatDate(value),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPicked(picked);
      },
    );
  }

  Widget _profitPreviewCard() {
    final isProfit = _previewProfit >= 0;
    final marginPct = _previewCharges > 0
        ? (_previewProfit / _previewCharges * 100).toStringAsFixed(1)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isProfit ? AppTheme.successColor : AppTheme.errorColor)
            .withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isProfit ? AppTheme.successColor : AppTheme.errorColor)
              .withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: isProfit ? AppTheme.successColor : AppTheme.errorColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Installation Profit',
                  style: TextStyle(fontSize: 12, color: AppTheme.mediumGray),
                ),
                Text(
                  DateTimeUtils.formatCurrency(_previewProfit),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isProfit ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ),
          if (marginPct != null)
            Text(
              '$marginPct% margin',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isProfit ? AppTheme.successColor : AppTheme.errorColor,
              ),
            ),
        ],
      ),
    );
  }
}
