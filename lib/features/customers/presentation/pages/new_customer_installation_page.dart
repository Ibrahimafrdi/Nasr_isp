import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:nasr_isp/config/service_locator.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
import 'package:nasr_isp/shared/widgets/adaptive_form_actions.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/core/utils/input_formatters.dart';
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
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

/// Onboards a brand-new subscriber together with their installation record
/// in a single form — contact & plan details plus installation date/type, cost, labor and profit.
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

  // Materials Used (BOM) state
  List<InstallationItemRow> _itemsUsedState = [];
  List<InventoryItemEntity> _allInventoryItems = [];
  bool _isLoadingInventory = true;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    context.read<EmployeeBloc>().add(const LoadEmployeesEvent());
    context.read<PackagesBloc>().add(const LoadPackagesEvent());
    _installationChargesController.addListener(_recomputePreview);
    _laborCostController.addListener(_recomputePreview);
    _monthlyBillController.addListener(_recomputePreview);
    _loadInventoryItems();
  }

  Future<void> _loadInventoryItems() async {
    try {
      final items = await getIt<GetInventoryItems>()();
      if (mounted) {
        setState(() {
          _allInventoryItems = items;
          _isLoadingInventory = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingInventory = false);
      }
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
    _monthlyBillController.removeListener(_recomputePreview);
    _monthlyBillController.dispose();
    _notesController.dispose();
    _installationChargesController.removeListener(_recomputePreview);
    _installationChargesController.dispose();
    _laborCostController.removeListener(_recomputePreview);
    _laborCostController.dispose();
    _installationRemarksController.dispose();
    super.dispose();
  }

  void _recomputePreview() => setState(() {});

  double get _previewCharges =>
      double.tryParse(_installationChargesController.text.trim()) ?? 0.0;

  double get _previewLabor =>
      double.tryParse(_laborCostController.text.trim()) ?? 0.0;

  double get _previewMaterialCost => _itemsUsedState.fold(
        0.0,
        (sum, row) =>
            sum +
            ((row['qty'] as int? ?? 0) * (row['unitCost'] as double? ?? 0.0)),
      );

  /// Installation Net Profit / Loss = Installation Fee Billed - Material Cost - Labour Cost
  double get _installationProfit =>
      _previewCharges - _previewMaterialCost - _previewLabor;

  double get _previewMonthlyPackageRate =>
      double.tryParse(_monthlyBillController.text.trim()) ?? 0.0;

  /// The upstream cost of the selected package, to snapshot onto the first
  /// month's charge.
  ///
  /// Null when no package is selected or it carries no cost price — recording
  /// zero would report the customer's whole bill as margin.
  double? _selectedPackageCost() {
    final id = _selectedPackageId;
    if (id == null || id.isEmpty) return null;
    final state = context.read<PackagesBloc>().state;
    if (state is! PackagesLoaded) return null;
    for (final pkg in state.packages) {
      if (pkg.id == id) return pkg.costPrice > 0 ? pkg.costPrice : null;
    }
    return null;
  }

  void _onPackageChanged(String? packageId, List<PackageEntity> packages) {
    if (packageId == null) return;
    final pkg = packages.firstWhere((p) => p.id == packageId);
    setState(() {
      _selectedPackageId = packageId;
      _monthlyBillController.text = pkg.price.toString();
    });
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Month-overflow safe (e.g. Jan 31 -> Feb 28), same rule the renewal flow
    // applies, so a customer onboarded here shares one billing cycle
    // definition with every customer onboarded any other way.
    final nextDueDate = BillingCycle.addMonths(_joinDate);

    final customerId = const Uuid().v4();

    final newCustomer = CustomerModel(
      id: customerId,
      name: _nameController.text.trim(),
      phone: AppInputFormatters.digitsOnly(_phoneController.text),
      cnic: AppInputFormatters.digitsOnly(_cnicController.text),
      address: _addressController.text.trim(),
      connectionType: _connectionType == ConnectionType.opticalFibre
          ? 'fiber'
          : 'wireless',
      packageId: _selectedPackageId,
      monthlyBill: _previewMonthlyPackageRate,
      status: CustomerEntity.statusActive,
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
      joinDate: _joinDate,
      nextDueDate: nextDueDate,
    );

    final customersBloc = context.read<CustomersBloc>();
    customersBloc.add(CreateCustomerEvent(newCustomer));

    try {
      final customerResult = await customersBloc.stream.firstWhere(
        (s) => s is CustomersLoaded || s is CustomersError,
      ).timeout(const Duration(seconds: 15));

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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer registration timed out or failed: ${e.toString()}'),
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
              .where((i) => i.id == row['itemId'])
              .firstOrNull
              ?.name ?? 'Material Item',
          quantity: row['qty'] as int,
          costPriceAtTime: row['unitCost'] as double,
          sellPriceAtTime: row['sellPrice'] as double? ?? row['unitCost'] as double,
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

    // Bill the first month, exactly as the plain Add Customer flow does.
    // Without this the customer counted toward the accrual run rate from day
    // one but had no charge in the ledger, so the dashboard reported them as
    // an uncollected renewal for a month they had already paid for at setup.
    context.read<PaymentsBloc>().add(
      CreatePaymentEvent(
        PaymentModel(
          id: const Uuid().v4(),
          customerId: customerId,
          customerName: newCustomer.name,
          amount: newCustomer.monthlyBill,
          paidAmount: newCustomer.monthlyBill,
          status: 'paid',
          type: PaymentType.subscription,
          billingMonth: BillingCycle.monthKey(_joinDate),
          dueDate: _joinDate,
          periodEnd: nextDueDate,
          completedDate: _joinDate,
          paymentDate: _joinDate,
          method: 'cash',
          packageCostAtBilling: _selectedPackageCost(),
          notes: 'First month bill collected at connection setup',
          createdAt: DateTime.now(),
        ),
      ),
    );

    final installationBloc = context.read<InstallationBloc>();
    installationBloc.add(CreateInstallationEvent(installation));

    try {
      final installationResult = await installationBloc.stream.firstWhere(
        (s) => s is InstallationLoaded || s is InstallationError,
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (installationResult is InstallationError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Customer created, but installation failed: ${installationResult.message}',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Installation registration timed out: ${e.toString()}'),
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
            final availablePackages = packagesState is PackagesLoaded
                ? packagesState.packages
                : <PackageEntity>[];

            return BlocBuilder<EmployeeBloc, EmployeeState>(
              builder: (context, employeeState) {
                final employees = employeeState is EmployeeLoaded
                    ? employeeState.employees
                          .where((e) => e.status == EmployeeStatus.active)
                          .toList()
                    : <EmployeeEntity>[];

                return Scaffold(
                  body: SingleChildScrollView(
                    padding: Responsive.pagePaddingFor(
                      Responsive.deviceTypeOf(context),
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: Responsive.cardPaddingFor(
                                  Responsive.deviceTypeOf(context),
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _sectionHeader(
                                        context,
                                        'Customer Information',
                                      ),
                                      const Divider(height: 24),
                                      _responsiveRow(context, [
                                        AppFormField(
                                          label: 'Full Name',
                                          isRequired: true,
                                          controller: _nameController,
                                          validator: (v) =>
                                              ValidationUtils.validateName(
                                                v,
                                                'Full Name',
                                              ),
                                        ),
                                        AppFormField(
                                          label: 'Phone Number',
                                          isRequired: true,
                                          controller: _phoneController,
                                          keyboardType: TextInputType.phone,
                                          inputFormatters:
                                              AppInputFormatters.phone,
                                          hintText: '0314 9498314',
                                          validator:
                                              ValidationUtils.validatePhonePk,
                                        ),
                                      ]),
                                      const SizedBox(height: 16),
                                      AppFormField(
                                        label: 'CNIC / National ID',
                                        isRequired: true,
                                        controller: _cnicController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters:
                                            AppInputFormatters.cnic,
                                        hintText: '17301-1937353-5',
                                        validator: ValidationUtils.validateCnic,
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

                                      _sectionHeader(
                                        context,
                                        'Subscription Package (Recurring Revenue)',
                                      ),
                                      const Divider(height: 24),
                                      _responsiveRow(context, [
                                        DropdownButtonFormField<ConnectionType>(
                                          initialValue: _connectionType,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            labelText:
                                                'Connection Type',
                                          ),
                                          items: ConnectionType.values
                                              .map(
                                                (t) => DropdownMenuItem(
                                                  value: t,
                                                  child: Text(t.displayName, overflow: TextOverflow.ellipsis),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(
                                                () => _connectionType = val,
                                              );
                                              _autoFillItemsForConnectionType(
                                                val,
                                              );
                                            }
                                          },
                                        ),
                                        DropdownButtonFormField<String>(
                                          initialValue: _selectedPackageId,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Select Internet Package',
                                          ),
                                          items: availablePackages
                                              .map(
                                                (pkg) => DropdownMenuItem(
                                                  value: pkg.id,
                                                  child: Text(
                                                    '${pkg.name} (${DateTimeUtils.formatCurrency(pkg.price)}/mo)',
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (val) => _onPackageChanged(
                                            val,
                                            availablePackages,
                                          ),
                                          validator: (v) =>
                                              (v == null || v.isEmpty)
                                              ? 'Select an internet package'
                                              : null,
                                        ),
                                      ]),
                                      const SizedBox(height: 16),
                                      AppFormField(
                                        label: 'Monthly Rate (PKR / Month)',
                                        isRequired: true,
                                        controller: _monthlyBillController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        inputFormatters:
                                            AppInputFormatters.decimal,
                                        validator: (v) =>
                                            ValidationUtils.validateAmount(
                                              v,
                                              fieldName: 'Monthly Rate',
                                            ),
                                      ),
                                      const SizedBox(height: 30),

                                      _sectionHeader(
                                        context,
                                        'One-Time Installation Details',
                                      ),
                                      const Divider(height: 24),
                                      _responsiveRow(context, [
                                        _datePickerTile(
                                          context,
                                          label: 'Installation Date',
                                          value: _installationDate,
                                          onPicked: (picked) => setState(() {
                                            _installationDate = picked;
                                          }),
                                        ),
                                        DropdownButtonFormField<String>(
                                          initialValue: _assignedEmployeeId,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            labelText:
                                                'Assigned Technician (Optional)',
                                          ),
                                          items: employees
                                              .map(
                                                (e) => DropdownMenuItem(
                                                  value: e.id,
                                                  child: Text(e.name, overflow: TextOverflow.ellipsis),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _assignedEmployeeId = val;
                                              _assignedEmployeeName = val == null
                                                  ? null
                                                  : employees
                                                        .firstWhere(
                                                          (e) => e.id == val,
                                                        )
                                                        .name;
                                            });
                                          },
                                        ),
                                      ]),
                                      const SizedBox(height: 16),
                                      AppFormField(
                                        label: 'Installation Fee Charged to Customer (PKR)',
                                        hintText: 'One-time setup fee billed to customer',
                                        isRequired: true,
                                        controller:
                                            _installationChargesController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        inputFormatters:
                                            AppInputFormatters.decimal,
                                        validator: (v) =>
                                            ValidationUtils.validateAmount(
                                              v,
                                              fieldName: 'Installation Fee',
                                              allowZero: true,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      _materialsUsedSection(),
                                      const SizedBox(height: 16),
                                      AppFormField(
                                        label: 'Labour Cost / Technician Pay (PKR)',
                                        controller: _laborCostController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        inputFormatters:
                                            AppInputFormatters.decimal,
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return null;
                                          }
                                          return double.tryParse(v.trim()) ==
                                                  null
                                              ? 'Enter a valid number'
                                              : null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      AppFormField(
                                        label: 'Installation Notes / Remarks',
                                        controller:
                                            _installationRemarksController,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 24),
                                      _financialSummaryCard(availablePackages),
                                      const SizedBox(height: 30),

                                      AdaptiveFormActions(
                                        secondary: OutlinedButton(
                                          onPressed: _isSaving
                                              ? null
                                              : () => context.go(
                                                  RoutePaths.customers,
                                                ),
                                          child: const Text('Cancel'),
                                        ),
                                        primary: ElevatedButton.icon(
                                          onPressed: _isSaving
                                              ? null
                                              : _saveForm,
                                          icon: const Icon(Icons.save),
                                          label: Text(
                                            _isSaving
                                                ? 'Saving...'
                                                : 'Create Customer & Installation',
                                          ),
                                        ),
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
    if (Responsive.isMobile(context)) {
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
          'Materials Used (optional — auto-filled based on connection type)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (_isLoadingInventory)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading inventory materials...', style: TextStyle(fontSize: 12, color: AppTheme.mediumGray)),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _itemsUsedState.length,
            itemBuilder: (context, idx) {
              final row = _itemsUsedState[idx];
              final itemId = row['itemId'] as String? ?? '';

              final itemDropdown = DropdownButtonFormField<String>(
                initialValue: itemId.isEmpty ? null : itemId,
                isExpanded: true,
                hint: const Text('Select Material', overflow: TextOverflow.ellipsis),
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
                onChanged: (val) {
                  if (val == null) return;
                  final selected = _allInventoryItems.firstWhere(
                    (i) => i.id == val,
                  );
                  setState(() {
                    row['itemId'] = val;
                    row['unitCost'] = selected.unitCost;
                    row['sellPrice'] = selected.sellPrice;
                  });
                },
              );

              final qtyField = SizedBox(
                width: 75,
                child: TextFormField(
                  key: ValueKey('qty_${itemId}_$idx'),
                  initialValue: (row['qty'] as int? ?? 1).toString(),
                  decoration: const InputDecoration(labelText: 'Qty'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final parsed = int.tryParse(val) ?? 0;
                    setState(() => row['qty'] = parsed);
                  },
                ),
              );

              final unitCostText = Text(
                'Unit Cost: ${DateTimeUtils.formatCurrency((row['unitCost'] as double? ?? 0.0))}',
                style: const TextStyle(fontSize: 12, color: AppTheme.mediumGray),
                overflow: TextOverflow.ellipsis,
              );

              final deleteButton = IconButton(
                icon: const Icon(Icons.delete, color: AppColors.errorRed),
                onPressed: () => setState(() => _itemsUsedState.removeAt(idx)),
              );

              if (Responsive.isMobile(context)) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      itemDropdown,
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          qtyField,
                          const SizedBox(width: 12),
                          Expanded(child: unitCostText),
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
                    Expanded(flex: 5, child: itemDropdown),
                    const SizedBox(width: 12),
                    qtyField,
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: unitCostText),
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
          label: const Text('Add Material Item'),
        ),
        if (_itemsUsedState.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Material Cost:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                DateTimeUtils.formatCurrency(_previewMaterialCost),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

  Widget _financialSummaryCard(List<PackageEntity> availablePackages) {
    final selectedPackageName = availablePackages
        .where((p) => p.id == _selectedPackageId)
        .firstOrNull
        ?.name ?? 'Selected Package';
    final isProfit = _installationProfit >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.lightGray.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Financial Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          
          // Recurring Monthly Subscription Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Package (Recurring Revenue)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedPackageName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${DateTimeUtils.formatCurrency(_previewMonthlyPackageRate)}/mo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'One-Time Installation Breakdown',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.mediumGray,
            ),
          ),
          const SizedBox(height: 12),

          _summaryRow(
            'Installation Fee Billed to Customer',
            '+ ${DateTimeUtils.formatCurrency(_previewCharges)}',
            isPositive: true,
          ),
          const SizedBox(height: 8),
          _summaryRow(
            'Material Cost',
            '- ${DateTimeUtils.formatCurrency(_previewMaterialCost)}',
            isNegative: true,
          ),
          const SizedBox(height: 8),
          _summaryRow(
            'Labour Cost / Technician Pay',
            '- ${DateTimeUtils.formatCurrency(_previewLabor)}',
            isNegative: true,
          ),

          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Installation Profit / Loss',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '(Installation Fee − Material Cost − Labour Cost)',
                    style: TextStyle(fontSize: 11, color: AppTheme.mediumGray),
                  ),
                ],
              ),
              Text(
                DateTimeUtils.formatCurrency(_installationProfit),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isProfit ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isPositive = false,
    bool isNegative = false,
  }) {
    Color valColor = Colors.black87;
    if (isPositive) valColor = AppTheme.successColor;
    if (isNegative) valColor = AppColors.errorRed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valColor,
          ),
        ),
      ],
    );
  }
}
