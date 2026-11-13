import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:nasr_isp/config/service_locator.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/input_formatters.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/customers/data/models/customer_model.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/features/employees/domain/entities/employee_entity.dart';
import 'package:nasr_isp/features/employees/presentation/bloc/employees_bloc.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_item_used_entity.dart';
import 'package:nasr_isp/features/installations/presentation/bloc/installations_bloc.dart';
import 'package:nasr_isp/features/installations/presentation/utils/installation_item_autofill.dart';
import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:nasr_isp/features/inventory/domain/usecases/get_inventory_items.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_bloc.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_event.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_state.dart';
import 'package:nasr_isp/features/payments/data/models/payment_model.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
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
  final _userIdController = TextEditingController();

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
  bool _isSummaryExpandedMobile = false;

  @override
  void initState() {
    super.initState();
    context.read<EmployeeBloc>().add(const LoadEmployeesEvent());
    context.read<PackagesBloc>().add(const LoadPackagesEvent());
    _installationChargesController.addListener(_recomputePreview);
    _laborCostController.addListener(_recomputePreview);
    _monthlyBillController.addListener(_recomputePreview);
    _nameController.addListener(_recomputePreview);
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
    _nameController.removeListener(_recomputePreview);
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _addressController.dispose();
    _monthlyBillController.removeListener(_recomputePreview);
    _monthlyBillController.dispose();
    _notesController.dispose();
    _userIdController.dispose();
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
        sum + ((row['qty'] as int? ?? 0) * (row['unitCost'] as double? ?? 0.0)),
  );

  // /// Installation Net Profit / Loss = Installation Fee Billed - Material Cost - Labour Cost
  // double get _installationProfit =>
  //     _previewCharges - _previewMaterialCost - _previewLabor;
  /// Upstream cost of the selected package (0 when none is selected or it
  /// has no cost price).
  double get _previewPackageCost => _selectedPackageCost() ?? 0.0;

  /// Setup Net Profit / Loss =
  /// Installation Fee Billed - Package Cost - Material Cost - Labour Cost
  double get _installationProfit =>
      _previewCharges -
      _previewPackageCost -
      _previewMaterialCost -
      _previewLabor;

  double get _previewMonthlyPackageRate =>
      double.tryParse(_monthlyBillController.text.trim()) ?? 0.0;

  bool get _hasUnsavedChanges {
    return _nameController.text.trim().isNotEmpty ||
        _phoneController.text.trim().isNotEmpty ||
        _cnicController.text.trim().isNotEmpty ||
        _addressController.text.trim().isNotEmpty ||
        _userIdController.text.trim().isNotEmpty ||
        _notesController.text.trim().isNotEmpty ||
        _installationChargesController.text.trim().isNotEmpty ||
        _installationRemarksController.text.trim().isNotEmpty ||
        _itemsUsedState.isNotEmpty ||
        _selectedPackageId != null;
  }

  Future<void> _handleCancel() async {
    if (_hasUnsavedChanges) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Discard this customer?'),
          content: const Text(
            'You have unsaved changes that will be lost. Are you sure you want to discard this new customer and installation?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Continue Editing'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (shouldDiscard == true && mounted) {
        context.go(RoutePaths.customers);
      }
    } else {
      context.go(RoutePaths.customers);
    }
  }

  /// The upstream cost of the selected package, to snapshot onto the first
  /// month's charge. Null when no package is selected or it carries no cost price.
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
    final pkg = packages.where((p) => p.id == packageId).firstOrNull;
    if (pkg != null) {
      setState(() {
        _selectedPackageId = packageId;
        _monthlyBillController.text = pkg.price.toString();
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPackageId == null || _selectedPackageId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an internet package.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Verify local row bounds (1..stock)
    for (final row in _itemsUsedState) {
      final qty = row['qty'] as int? ?? 0;
      final item = _allInventoryItems
          .where((i) => i.id == row['itemId'])
          .firstOrNull;
      final stock = item?.quantityInStock ?? 0;
      if (qty < 1 || qty > stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item?.name ?? "Material item"}: quantity must be between 1 and $stock.',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    // PART 1, STEP 6: Re-fetch inventory (GetInventoryItems) and verify
    // every row's quantity is still within stock BEFORE creating anything.
    try {
      final freshInventory = await getIt<GetInventoryItems>()();
      if (mounted) {
        setState(() => _allInventoryItems = freshInventory);
      }
      for (final row in _itemsUsedState) {
        final freshItem = freshInventory
            .where((i) => i.id == row['itemId'])
            .firstOrNull;
        final reqQty = row['qty'] as int? ?? 0;
        if (freshItem == null || freshItem.quantityInStock < reqQty) {
          final avail = freshItem?.quantityInStock ?? 0;
          final name = freshItem?.name ?? 'Material item';
          if (mounted) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name: only $avail left in stock'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify inventory stock: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

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
      userId: _userIdController.text.trim(),
      createdAt: DateTime.now(),
      joinDate: _joinDate,
      nextDueDate: nextDueDate,
    );

    final customersBloc = context.read<CustomersBloc>();
    customersBloc.add(CreateCustomerEvent(newCustomer));

    try {
      final customerResult = await customersBloc.stream
          .firstWhere((s) => s is CustomersLoaded || s is CustomersError)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (customerResult is CustomersError) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create customer: ${customerResult.message}',
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
          content: Text(
            'Customer registration timed out or failed: ${e.toString()}',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final itemsUsed = <InstallationItemUsedEntity>[
      for (final row in _itemsUsedState)
        InstallationItemUsedEntity(
          inventoryItemId: row['itemId'] as String,
          itemName:
              _allInventoryItems
                  .where((i) => i.id == row['itemId'])
                  .firstOrNull
                  ?.name ??
              'Material Item',
          quantity: row['qty'] as int,
          costPriceAtTime: row['unitCost'] as double,
          sellPriceAtTime:
              row['sellPrice'] as double? ?? row['unitCost'] as double,
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
      final installationResult = await installationBloc.stream
          .firstWhere((s) => s is InstallationLoaded || s is InstallationError)
          .timeout(const Duration(seconds: 15));

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

        final isAdmin = authState.user.isAdmin;

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

                return PopScope(
                  canPop: !_hasUnsavedChanges,
                  onPopInvokedWithResult: (didPop, _) {
                    if (!didPop) _handleCancel();
                  },
                  child: Scaffold(
                    backgroundColor: AppTheme.veryLightGray,
                    body: LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 900;
                        final pagePadding = Responsive.pagePaddingFor(
                          Responsive.deviceTypeOf(context),
                        );

                        return SingleChildScrollView(
                          padding: pagePadding,
                          child: Form(
                            key: _formKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Breadcrumb(
                                  items: [
                                    BreadcrumbItem(
                                      label: 'Home',
                                      onTap: () =>
                                          context.go(RoutePaths.dashboard),
                                    ),
                                    BreadcrumbItem(
                                      label: 'Customers',
                                      onTap: () =>
                                          context.go(RoutePaths.customers),
                                    ),
                                    BreadcrumbItem(label: 'New Customer'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'New Customer & Installation',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Register customer profile, subscribe to package, and schedule installation with materials in one step.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.darkGray,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (isDesktop)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 65,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _buildCustomerSection(context),
                                            const SizedBox(height: 20),
                                            _buildPackageSection(
                                              context,
                                              availablePackages,
                                            ),
                                            const SizedBox(height: 20),
                                            _buildInstallationSection(
                                              context,
                                              employees,
                                              isAdmin,
                                            ),
                                            const SizedBox(height: 40),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        flex: 35,
                                        child: _InstallationSummaryCard(
                                          name: _nameController.text.trim(),
                                          selectedPackageId: _selectedPackageId,
                                          availablePackages: availablePackages,
                                          monthlyRate:
                                              _previewMonthlyPackageRate,
                                          installationCharges: _previewCharges,
                                          itemsUsedCount:
                                              _itemsUsedState.length,
                                          previewMaterialCost:
                                              _previewMaterialCost,
                                          previewLabor: _previewLabor,
                                          installationProfit:
                                              _installationProfit,
                                          isAdmin: isAdmin,
                                          isSaving: _isSaving,
                                          onSave: _saveForm,
                                          onCancel: _handleCancel,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildCustomerSection(context),
                                      const SizedBox(height: 16),
                                      _buildPackageSection(
                                        context,
                                        availablePackages,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildInstallationSection(
                                        context,
                                        employees,
                                        isAdmin,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildMobileCollapsibleSummaryCard(
                                        availablePackages,
                                        isAdmin,
                                      ),
                                      const SizedBox(height: 80),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    bottomNavigationBar: constraintsIsMobile(context)
                        ? _buildMobileBottomBar()
                        : null,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  bool constraintsIsMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 900;
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String number,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightGray),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              context,
              number: number,
              title: title,
              subtitle: subtitle,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.lightGray),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(
    BuildContext context, {
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.darkGray),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSection(BuildContext context) {
    return _buildSectionCard(
      context: context,
      number: '1',
      title: 'Customer Information',
      subtitle:
          'Subscriber identity, contact numbers and physical installation address',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _responsiveRow(context, [
            AppFormField(
              label: 'Full Name',
              isRequired: true,
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              validator: (v) => ValidationUtils.validateName(v, 'Full Name'),
            ),
            AppFormField(
              label: 'Phone Number',
              isRequired: true,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: AppInputFormatters.phone,
              hintText: '0314 9498314',
              validator: ValidationUtils.validatePhonePk,
            ),
          ]),
          const SizedBox(height: 16),
          _responsiveRow(context, [
            AppFormField(
              label: 'CNIC / National ID',
              isRequired: true,
              controller: _cnicController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: AppInputFormatters.cnic,
              hintText: '17301-1937353-5',
              validator: ValidationUtils.validateCnic,
            ),
            AppFormField(
              label: 'User ID',
              hintText: 'e.g. user_pppoe_101',
              controller: _userIdController,
              isRequired: true,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'User ID is required';
                }
                return null;
              },
            ),
          ]),
          const SizedBox(height: 16),
          AppFormField(
            label: 'Installation Physical Address',
            controller: _addressController,
            textInputAction: TextInputAction.next,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          AppFormField(
            label: 'Notes / Remarks',
            controller: _notesController,
            textInputAction: TextInputAction.next,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _datePickerTile(
            context,
            label: 'Join Date',
            value: _joinDate,
            onPicked: (picked) => setState(() => _joinDate = picked),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageSection(
    BuildContext context,
    List<PackageEntity> availablePackages,
  ) {
    return _buildSectionCard(
      context: context,
      number: '2',
      title: 'Internet Package',
      subtitle: 'Select transmission media and recurring subscription tier',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connection Type',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ConnectionType>(
            segments: const [
              ButtonSegment(
                value: ConnectionType.wireless,
                label: Text('Wireless'),
                icon: Icon(Icons.wifi, size: 18),
              ),
              ButtonSegment(
                value: ConnectionType.opticalFibre,
                label: Text('Optical Fibre'),
                icon: Icon(Icons.cable, size: 18),
              ),
            ],
            selected: {_connectionType},
            onSelectionChanged: (Set<ConnectionType> newSelection) {
              final val = newSelection.first;
              setState(() => _connectionType = val);
              _autoFillItemsForConnectionType(val);
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primaryBlue.withValues(
                alpha: 0.12,
              ),
              selectedForegroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _selectedPackageId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Select Internet Package *',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            items: availablePackages.map((pkg) {
              return DropdownMenuItem(
                value: pkg.id,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pkg.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${pkg.speedMbps > 0 ? "${pkg.speedMbps} Mbps  ·  " : ""}${DateTimeUtils.formatCurrency(pkg.price)}/mo',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) => _onPackageChanged(val, availablePackages),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Select an internet package' : null,
          ),
          const SizedBox(height: 16),
          AppFormField(
            label: 'Monthly Rate (PKR / Month)',
            isRequired: true,
            controller: _monthlyBillController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: AppInputFormatters.decimal,
            validator: (v) =>
                ValidationUtils.validateAmount(v, fieldName: 'Monthly Rate'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationSection(
    BuildContext context,
    List<EmployeeEntity> employees,
    bool isAdmin,
  ) {
    return _buildSectionCard(
      context: context,
      number: '3',
      title: 'Installation & Materials',
      subtitle:
          'Technician allocation, installation charges and stock materials used',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _responsiveRow(context, [
            _datePickerTile(
              context,
              label: 'Installation Date',
              value: _installationDate,
              onPicked: (picked) => setState(() => _installationDate = picked),
            ),
            DropdownButtonFormField<String>(
              initialValue: _assignedEmployeeId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Assigned Technician (Optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
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
                      : employees.where((e) => e.id == val).firstOrNull?.name;
                });
              },
            ),
          ]),
          const SizedBox(height: 16),
          AppFormField(
            label: 'Installation Fee Charged to Customer (PKR)',
            hintText: '0 for free setup, or setup fee billed',
            isRequired: true,
            controller: _installationChargesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: AppInputFormatters.decimal,
            validator: (v) => ValidationUtils.validateAmount(
              v,
              fieldName: 'Installation Fee',
              allowZero: true,
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 16),
            AppFormField(
              label: 'Labour Cost / Technician Pay (PKR)',
              controller: _laborCostController,
              hintText: '0',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: AppInputFormatters.decimal,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                return double.tryParse(v.trim()) == null
                    ? 'Enter a valid number'
                    : null;
              },
            ),
          ],
          const SizedBox(height: 20),
          _MaterialsUsedSection(
            itemsUsedState: _itemsUsedState,
            allInventoryItems: _allInventoryItems,
            isLoading: _isLoadingInventory,
            isAdmin: isAdmin,
            onItemChanged: (index, newItemId) {
              final selected = _allInventoryItems
                  .where((i) => i.id == newItemId)
                  .firstOrNull;
              if (selected == null) return;
              setState(() {
                final row = _itemsUsedState[index];
                row['itemId'] = newItemId;
                row['unitCost'] = selected.unitCost;
                row['sellPrice'] = selected.sellPrice;
                final currentQty = row['qty'] as int? ?? 1;
                if (currentQty > selected.quantityInStock) {
                  row['qty'] = selected.quantityInStock >= 1
                      ? selected.quantityInStock
                      : 1;
                }
              });
            },
            onQtyChanged: (index, newQty) {
              setState(() {
                _itemsUsedState[index]['qty'] = newQty;
              });
            },
            onDeleteRow: (index) {
              setState(() {
                _itemsUsedState.removeAt(index);
              });
            },
            onAddRow: () {
              final remainingInStock = _allInventoryItems
                  .where(
                    (i) =>
                        i.quantityInStock > 0 &&
                        !_itemsUsedState.any((r) => r['itemId'] == i.id),
                  )
                  .toList();
              if (remainingInStock.isEmpty) return;
              final next = remainingInStock.first;
              setState(() {
                _itemsUsedState.add({
                  'itemId': next.id,
                  'qty': 1,
                  'unitCost': next.unitCost,
                  'sellPrice': next.sellPrice,
                });
              });
            },
          ),
          const SizedBox(height: 16),
          AppFormField(
            label: 'Installation Notes / Remarks',
            controller: _installationRemarksController,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCollapsibleSummaryCard(
    List<PackageEntity> availablePackages,
    bool isAdmin,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightGray),
      ),
      color: Colors.white,
      child: ExpansionTile(
        initiallyExpanded: _isSummaryExpandedMobile,
        onExpansionChanged: (v) => setState(() => _isSummaryExpandedMobile = v),
        title: const Text(
          'Installation & Financial Summary',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          'Fee: ${DateTimeUtils.formatCurrency(_previewCharges)}${isAdmin ? "  ·  Profit: ${DateTimeUtils.formatCurrency(_installationProfit)}" : ""}',
          style: const TextStyle(fontSize: 12, color: AppColors.darkGray),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _InstallationSummaryContent(
              name: _nameController.text.trim(),
              selectedPackageId: _selectedPackageId,
              availablePackages: availablePackages,
              monthlyRate: _previewMonthlyPackageRate,
              installationCharges: _previewCharges,
              itemsUsedCount: _itemsUsedState.length,
              previewMaterialCost: _previewMaterialCost,
              previewLabor: _previewLabor,
              installationProfit: _installationProfit,
              isAdmin: isAdmin,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.lightGray)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _handleCancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  _isSaving ? 'Saving...' : 'Create Customer & Installation',
                ),
              ),
            ),
          ],
        ),
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

  Widget _datePickerTile(
    BuildContext context, {
    required String label,
    required DateTime value,
    required void Function(DateTime) onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.darkGray,
                    ),
                  ),
                  Text(
                    DateTimeUtils.formatDate(value),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MaterialsUsedSection extends StatelessWidget {
  final List<InstallationItemRow> itemsUsedState;
  final List<InventoryItemEntity> allInventoryItems;
  final bool isLoading;
  final bool isAdmin;
  final void Function(int index, String newItemId) onItemChanged;
  final void Function(int index, int newQty) onQtyChanged;
  final void Function(int index) onDeleteRow;
  final VoidCallback onAddRow;

  const _MaterialsUsedSection({
    required this.itemsUsedState,
    required this.allInventoryItems,
    required this.isLoading,
    required this.isAdmin,
    required this.onItemChanged,
    required this.onQtyChanged,
    required this.onDeleteRow,
    required this.onAddRow,
  });

  @override
  Widget build(BuildContext context) {
    final remainingInStock = allInventoryItems
        .where(
          (i) =>
              i.quantityInStock > 0 &&
              !itemsUsedState.any((r) => r['itemId'] == i.id),
        )
        .toList();
    final canAddMore = remainingInStock.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Materials Used',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${itemsUsedState.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            if (canAddMore)
              TextButton.icon(
                onPressed: onAddRow,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Material'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'Loading stock materials...',
                  style: TextStyle(fontSize: 12, color: AppColors.darkGray),
                ),
              ],
            ),
          )
        else if (itemsUsedState.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 32,
                  color: AppColors.mediumGray,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No materials added',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Allocate cables, routers or ONU units used for this installation.',
                  style: TextStyle(fontSize: 12, color: AppColors.darkGray),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: canAddMore ? onAddRow : null,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Material Item'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemsUsedState.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final row = itemsUsedState[idx];
              final currentItemId = row['itemId'] as String? ?? '';
              final invItem = allInventoryItems
                  .where((i) => i.id == currentItemId)
                  .firstOrNull;

              final stock = invItem?.quantityInStock ?? 0;
              final reorder = invItem?.reorderLevel ?? 0;
              final qty = row['qty'] as int? ?? 1;
              final unitCost = row['unitCost'] as double? ?? 0.0;
              final lineCost = qty * unitCost;

              // Rule 1 & Rule 3: Only in-stock items, excluding items used in other rows
              // (except the item currently selected in this row).
              final availableOptions = allInventoryItems.where((item) {
                final isCurrent = item.id == currentItemId;
                final isUsedElsewhere = itemsUsedState.asMap().entries.any(
                  (entry) =>
                      entry.key != idx && entry.value['itemId'] == item.id,
                );
                return (item.quantityInStock > 0 && !isUsedElsewhere) ||
                    isCurrent;
              }).toList();

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: currentItemId.isEmpty ? null : currentItemId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            items: availableOptions.map((item) {
                              return DropdownMenuItem(
                                value: item.id,
                                child: Text(
                                  item.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) onItemChanged(idx, val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.errorRed,
                            size: 20,
                          ),
                          tooltip: 'Remove',
                          onPressed: () => onDeleteRow(idx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Stock Badge
                        _StockBadge(stock: stock, reorderLevel: reorder),
                        const Spacer(),
                        // Quantity Stepper
                        _QuantityStepper(
                          qty: qty,
                          maxStock: stock,
                          onChanged: (newQty) => onQtyChanged(idx, newQty),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                DateTimeUtils.formatCurrency(lineCost),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.charcoal,
                                ),
                              ),
                              Text(
                                '@ ${DateTimeUtils.formatCurrency(unitCost)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.darkGray,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        if (itemsUsedState.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (canAddMore)
                OutlinedButton.icon(
                  onPressed: onAddRow,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Another Material'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                  ),
                )
              else
                const Text(
                  'No more items in stock',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.darkGray,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (isAdmin)
                Text(
                  'Total Material: ${DateTimeUtils.formatCurrency(itemsUsedState.fold(0.0, (sum, r) => sum + ((r["qty"] as int? ?? 0) * (r["unitCost"] as double? ?? 0.0))))}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.charcoal,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  final int reorderLevel;

  const _StockBadge({required this.stock, required this.reorderLevel});

  @override
  Widget build(BuildContext context) {
    final isLow = stock <= reorderLevel;
    final isOut = stock <= 0;

    Color bg = const Color(0xFFF0FDF4);
    Color border = const Color(0xFFBBF7D0);
    Color text = const Color(0xFF15803D);

    if (isOut) {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFECACA);
      text = AppColors.errorRed;
    } else if (isLow) {
      bg = const Color(0xFFFEF3C7);
      border = const Color(0xFFFDE68A);
      text = const Color(0xFFB45309);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        isOut ? 'Out of Stock' : 'In stock: $stock',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatefulWidget {
  final int qty;
  final int maxStock;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({
    required this.qty,
    required this.maxStock,
    required this.onChanged,
  });

  @override
  State<_QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<_QuantityStepper> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.qty.toString());
  }

  @override
  void didUpdateWidget(covariant _QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.qty != oldWidget.qty) {
      _controller.text = widget.qty.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canDec = widget.qty > 1;
    final bool canInc = widget.qty < widget.maxStock;
    final bool isOverMax = widget.qty > widget.maxStock;
    final bool isUnderMin = widget.qty < 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: (isOverMax || isUnderMin)
                  ? AppColors.errorRed
                  : AppColors.lightGray,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 14),
                onPressed: canDec
                    ? () {
                        widget.onChanged(widget.qty - 1);
                      }
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 34),
              ),
              SizedBox(
                width: 44,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(v) ?? 0;
                    widget.onChanged(parsed);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 14),
                onPressed: canInc
                    ? () {
                        widget.onChanged(widget.qty + 1);
                      }
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 34),
              ),
            ],
          ),
        ),
        if (isOverMax)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Max ${widget.maxStock}',
              style: const TextStyle(
                color: AppColors.errorRed,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else if (isUnderMin)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              'Min 1',
              style: const TextStyle(
                color: AppColors.errorRed,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _InstallationSummaryCard extends StatelessWidget {
  final String name;
  final String? selectedPackageId;
  final List<PackageEntity> availablePackages;
  final double monthlyRate;
  final double installationCharges;
  final int itemsUsedCount;
  final double previewMaterialCost;
  final double previewLabor;
  final double installationProfit;
  final bool isAdmin;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _InstallationSummaryCard({
    required this.name,
    required this.selectedPackageId,
    required this.availablePackages,
    required this.monthlyRate,
    required this.installationCharges,
    required this.itemsUsedCount,
    required this.previewMaterialCost,
    required this.previewLabor,
    required this.installationProfit,
    required this.isAdmin,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightGray),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Summary & Financials',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.lightGray),
            const SizedBox(height: 16),
            _InstallationSummaryContent(
              name: name,
              selectedPackageId: selectedPackageId,
              availablePackages: availablePackages,
              monthlyRate: monthlyRate,
              installationCharges: installationCharges,
              itemsUsedCount: itemsUsedCount,
              previewMaterialCost: previewMaterialCost,
              previewLabor: previewLabor,
              installationProfit: installationProfit,
              isAdmin: isAdmin,
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.lightGray),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  isSaving ? 'Saving...' : 'Create Customer & Installation',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: isSaving ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstallationSummaryContent extends StatelessWidget {
  final String name;
  final String? selectedPackageId;
  final List<PackageEntity> availablePackages;
  final double monthlyRate;
  final double installationCharges;
  final int itemsUsedCount;
  final double previewMaterialCost;
  final double previewLabor;
  final double installationProfit;
  final bool isAdmin;

  const _InstallationSummaryContent({
    required this.name,
    required this.selectedPackageId,
    required this.availablePackages,
    required this.monthlyRate,
    required this.installationCharges,
    required this.itemsUsedCount,
    required this.previewMaterialCost,
    required this.previewLabor,
    required this.installationProfit,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final pkg = availablePackages
        .where((p) => p.id == selectedPackageId)
        .firstOrNull;
    final packageName = pkg?.name ?? 'Not selected';
    final isProfit = installationProfit >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subscriber
        _summaryRow(
          label: 'Subscriber',
          value: name.isEmpty ? 'New Customer' : name,
          isBold: true,
        ),
        const SizedBox(height: 10),

        // Recurring Monthly Plan Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Subscription',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      packageName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${DateTimeUtils.formatCurrency(monthlyRate)}/mo',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        const Text(
          'One-Time Setup Breakdown',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 10),

        _summaryRow(
          label: 'Installation Fee Billed',
          value: '+ ${DateTimeUtils.formatCurrency(installationCharges)}',
          valueColor: AppTheme.successColor,
        ),
        const SizedBox(height: 8),

        _summaryRow(
          label: 'Allocated Materials',
          value: '$itemsUsedCount items',
        ),

        if (isAdmin) ...[
          const SizedBox(height: 8),
          _summaryRow(
            label: 'Package Cost Price',
            value: '- ${DateTimeUtils.formatCurrency(pkg?.costPrice ?? 0)}',
            valueColor: AppColors.errorRed,
          ),
          const SizedBox(height: 8),
          _summaryRow(
            label: 'Material Stock Cost',
            value: '- ${DateTimeUtils.formatCurrency(previewMaterialCost)}',
            valueColor: AppColors.errorRed,
          ),
          const SizedBox(height: 8),
          _summaryRow(
            label: 'Technician Labour Pay',
            value: '- ${DateTimeUtils.formatCurrency(previewLabor)}',
            valueColor: AppColors.errorRed,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.lightGray),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isProfit ? 'Estimated Profit' : 'Estimated Loss',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '(Fee − Package − Materials − Labour)',
                    style: TextStyle(fontSize: 10, color: AppColors.darkGray),
                  ),
                ],
              ),
              Text(
                DateTimeUtils.formatCurrency(installationProfit),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isProfit ? AppTheme.successColor : AppColors.errorRed,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.charcoal),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}
