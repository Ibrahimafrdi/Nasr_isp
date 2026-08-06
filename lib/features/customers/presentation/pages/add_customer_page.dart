import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/core/utils/input_formatters.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
import 'package:nasr_isp/shared/widgets/adaptive_form_actions.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_bloc.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_state.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:uuid/uuid.dart';

class AddCustomerPage extends StatefulWidget {
  final String? customerId;

  const AddCustomerPage({super.key, this.customerId});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _cnicController;
  late TextEditingController _addressController;
  late TextEditingController _monthlyBillController;
  // late TextEditingController _installationCostController;
  late TextEditingController _notesController;

  ConnectionType _selectedConnectionType = ConnectionType.wireless;
  String? _selectedPackageId;
  bool _isSaving = false;
  DateTime _joinDate = DateTime.now();

  String? _existingStatus;
  DateTime? _existingCreatedAt;
  DateTime? _existingNextDueDate;

  // True whenever we're editing an existing customer and haven't yet
  // confirmed their real status/createdAt — saving in this window would
  // silently fall back to 'active'/now and corrupt those fields.
  bool _isLoadingExisting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _cnicController = TextEditingController();
    _addressController = TextEditingController();
    _monthlyBillController = TextEditingController();
    // _installationCostController = TextEditingController();
    _notesController = TextEditingController();
    _isLoadingExisting = widget.customerId != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomerData();
    });
  }

  void _loadCustomerData() {
    if (widget.customerId == null) {
      _setDefaultPackage();
      return;
    }

    // Try BLoC state first (all customers, not just paginated)
    final customersState = context.read<CustomersBloc>().state;
    if (customersState is CustomersLoaded) {
      // Search across ALL loaded customers
      try {
        final customer = customersState.customers.firstWhere(
          (c) => c.id == widget.customerId,
        );
        _fillForm(customer);
        return;
      } catch (_) {
        // Not found in current page — trigger a fresh full load
      }
    }

    // Fallback: reload without filters to get all customers
    context.read<CustomersBloc>().add(const LoadCustomersEvent());

    // Listen for state change via addPostFrameCallback retry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final state = context.read<CustomersBloc>().state;
        if (state is CustomersLoaded) {
          try {
            final customer = state.customers.firstWhere(
              (c) => c.id == widget.customerId,
            );
            _fillForm(customer);
          } catch (_) {
            // Customer truly not found — stop blocking Save on a load that
            // will never resolve; _saveForm still guards on _existingStatus.
            setState(() => _isLoadingExisting = false);
          }
        } else {
          setState(() => _isLoadingExisting = false);
        }
      });
    });
  }

  void _fillForm(CustomerModel customer) {
    setState(() {
      _nameController.text = customer.name;
      _phoneController.text = AppInputFormatters.formatPhone(customer.phone);
      _cnicController.text = AppInputFormatters.formatCnic(customer.cnic);
      _addressController.text = customer.address;
      _selectedConnectionType = customer.connectionType == 'fiber'
          ? ConnectionType.opticalFibre
          : ConnectionType.wireless;
      _monthlyBillController.text = customer.monthlyBill.toString();
      // _installationCostController.text = customer.installationCost.toString();
      _selectedPackageId = customer.packageId;
      _notesController.text = customer.notes;
      _existingStatus = customer.status;
      _existingCreatedAt = customer.createdAt;
      _existingNextDueDate = customer.nextDueDate;
      if (customer.joinDate != null) _joinDate = customer.joinDate!;
      _isLoadingExisting = false;
    });
  }

  void _setDefaultPackage() {
    final packagesState = context.read<PackagesBloc>().state;
    if (packagesState is PackagesLoaded) {
      if (packagesState.packages.isNotEmpty) {
        setState(() {
          _selectedPackageId = packagesState.packages.first.id;
          _monthlyBillController.text = packagesState.packages.first.price
              .toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _addressController.dispose();
    _monthlyBillController.dispose();
    // _installationCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// The upstream cost of the selected package, to snapshot onto the first
  /// month's charge.
  ///
  /// Null when no package is selected or the package carries no cost price:
  /// recording zero would report the customer's whole bill as margin, which is
  /// the overstatement the dashboard's `unpricedCustomerCount` exists to warn
  /// about.
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

  void _onPackageChanged(String? packageId) {
    if (packageId != null) {
      final packagesState = context.read<PackagesBloc>().state;
      if (packagesState is PackagesLoaded) {
        final pkg = packagesState.packages.firstWhere((p) => p.id == packageId);
        setState(() {
          _selectedPackageId = packageId;
          _monthlyBillController.text = pkg.price.toString();
        });
      }
    }
  }

  void _saveForm() async {
    if (widget.customerId != null && _isLoadingExisting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the customer data to finish loading.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      // Only derive nextDueDate for brand-new customers. On an edit the
      // stored value is authoritative — the Renew action advances it on every
      // renewal, so recomputing from joinDate would rewind the billing cycle
      // just because someone corrected a phone number.
      final nextDueDate = widget.customerId == null
          ? BillingCycle.addMonths(_joinDate)
          : (_existingNextDueDate ?? BillingCycle.addMonths(_joinDate));

      final customerId = widget.customerId ?? const Uuid().v4();

      final newCustomer = CustomerModel(
        id: customerId,
        name: _nameController.text.trim(),
        phone: AppInputFormatters.digitsOnly(_phoneController.text),
        cnic: AppInputFormatters.digitsOnly(_cnicController.text),
        address: _addressController.text.trim(),
        connectionType: _selectedConnectionType == ConnectionType.opticalFibre
            ? 'fiber'
            : 'wireless',
        packageId: _selectedPackageId,
        monthlyBill: double.tryParse(_monthlyBillController.text.trim()) ?? 0.0,
        status: _existingStatus ?? 'active',
        notes: _notesController.text.trim(),
        createdAt: _existingCreatedAt ?? DateTime.now(),
        joinDate: _joinDate,
        nextDueDate: nextDueDate,
      );

      if (widget.customerId == null) {
        // CREATE new customer
        context.read<CustomersBloc>().add(CreateCustomerEvent(newCustomer));

        // The first month is billed here, in exactly the shape a renewal
        // produces — same (customerId, billingMonth) key, same cost snapshot,
        // same covered period — so month one reconciles against the accrual
        // run rate alongside every month that follows it.
        final firstPayment = PaymentModel(
          id: const Uuid().v4(),
          customerId: customerId,
          customerName: newCustomer.name,
          amount: newCustomer.monthlyBill,
          paidAmount: newCustomer.monthlyBill,
          billingMonth: BillingCycle.monthKey(_joinDate),
          // The day the connection was sold, not the next expiry.
          dueDate: _joinDate,
          periodEnd: nextDueDate,
          completedDate: _joinDate,
          paymentDate: _joinDate,
          method: 'cash',
          status: 'paid',
          type: PaymentType.subscription,
          packageCostAtBilling: _selectedPackageCost(),
          notes: 'First month bill collected at connection setup',
          createdAt: DateTime.now(),
        );
        context.read<PaymentsBloc>().add(CreatePaymentEvent(firstPayment));

        // Wait for Firestore write then navigate
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscriber account created successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.go(RoutePaths.customers);
      } else {
        // UPDATE existing customer
        context.read<CustomersBloc>().add(UpdateCustomerEvent(newCustomer));

        // Wait for Firestore write + BLoC reload to complete
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;

        // Trigger a fresh load to ensure list reflects update
        context.read<CustomersBloc>().add(const LoadCustomersEvent());

        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscriber details updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.go(RoutePaths.customers);
      }

      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.customerId != null;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: Text('Not authenticated')));
        }

        return BlocBuilder<PackagesBloc, PackagesState>(
          builder: (context, packagesState) {
            List<PackageEntity> availablePackages = [];

            if (packagesState is PackagesLoaded) {
              availablePackages = packagesState.packages;
            }

            return Scaffold(
              body: SingleChildScrollView(
                padding: Responsive.pagePaddingFor(Responsive.deviceTypeOf(context)),
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
                          label: isEditMode
                              ? 'Modify Profile'
                              : 'New Subscription',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isEditMode ? 'Edit Account' : 'Provisioning Form',
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: Responsive.cardPaddingFor(
                              Responsive.deviceTypeOf(context),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Account Information",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const Divider(height: 24),
                                  Responsive.isMobile(context)
                                      ? Column(
                                          children: [
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
                                            const SizedBox(height: 16),
                                            AppFormField(
                                              label: 'Phone Number',
                                              isRequired: true,
                                              controller: _phoneController,
                                              keyboardType: TextInputType.phone,
                                              inputFormatters:
                                                  AppInputFormatters.phone,
                                              hintText: '0314 9498314',
                                              validator: ValidationUtils
                                                  .validatePhonePk,
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: AppFormField(
                                                label: 'Full Name',
                                                isRequired: true,
                                                controller: _nameController,
                                                validator: (v) =>
                                                    ValidationUtils.validateName(
                                                      v,
                                                      'Full Name',
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: AppFormField(
                                                label: 'Phone Number',
                                                isRequired: true,
                                                controller: _phoneController,
                                                keyboardType:
                                                    TextInputType.phone,
                                                inputFormatters:
                                                    AppInputFormatters.phone,
                                                hintText: '0314 9498314',
                                                validator: ValidationUtils
                                                    .validatePhonePk,
                                              ),
                                            ),
                                          ],
                                        ),
                                  const SizedBox(height: 16),
                                  Responsive.isMobile(context)
                                      ? Column(
                                          children: [
                                            AppFormField(
                                              label: 'CNIC / National ID',
                                              isRequired: true,
                                              controller: _cnicController,
                                              keyboardType: TextInputType.number,
                                              inputFormatters:
                                                  AppInputFormatters.cnic,
                                              hintText: '17301-1937353-5',
                                              validator:
                                                  ValidationUtils.validateCnic,
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: AppFormField(
                                                label: 'CNIC / National ID',
                                                isRequired: true,
                                                controller: _cnicController,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters:
                                                    AppInputFormatters.cnic,
                                                hintText: '17301-1937353-5',
                                                validator: ValidationUtils
                                                    .validateCnic,
                                              ),
                                            ),
                                          ],
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
                                  // Join Date picker
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                      Icons.calendar_today,
                                      color: AppColors.primaryBlue,
                                    ),
                                    title: const Text(
                                      'Join Date',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      DateTimeUtils.formatDate(_joinDate),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _joinDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) {
                                        setState(() => _joinDate = picked);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 30),
                                  Text(
                                    "Plan & Pricing Details",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const Divider(height: 24),
                                  Responsive.isMobile(context)
                                      ? Column(
                                          children: [
                                            DropdownButtonFormField<
                                              ConnectionType
                                            >(
                                              initialValue:
                                                  _selectedConnectionType,
                                              decoration: const InputDecoration(
                                                labelText: 'Connection Type',
                                              ),
                                              items: ConnectionType.values.map((
                                                type,
                                              ) {
                                                return DropdownMenuItem(
                                                  value: type,
                                                  child: Text(type.displayName),
                                                );
                                              }).toList(),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(() {
                                                    _selectedConnectionType =
                                                        val;
                                                  });
                                                }
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                            DropdownButtonFormField<String>(
                                              initialValue: availablePackages
                                                      .any((p) =>
                                                          p.id ==
                                                          _selectedPackageId)
                                                  ? _selectedPackageId
                                                  : null,
                                              decoration: const InputDecoration(
                                                labelText: 'Select Package',
                                                helperText:
                                                    'Sets the upstream cost used for monthly profit',
                                              ),
                                              hint:
                                                  const Text('Select Package'),
                                              items: availablePackages.map((
                                                pkg,
                                              ) {
                                                return DropdownMenuItem(
                                                  value: pkg.id,
                                                  child: Text(pkg.name),
                                                );
                                              }).toList(),
                                              onChanged: _onPackageChanged,
                                              // Required: without a package there
                                              // is no upstream cost to subtract,
                                              // and the customer's whole bill
                                              // would be reported as profit.
                                              validator: (v) =>
                                                  (v == null || v.isEmpty)
                                                      ? 'Select a package — it sets the cost side of profit'
                                                      : null,
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child:
                                                  DropdownButtonFormField<
                                                    ConnectionType
                                                  >(
                                                    initialValue:
                                                        _selectedConnectionType,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Connection Type',
                                                        ),
                                                    items: ConnectionType.values
                                                        .map((type) {
                                                          return DropdownMenuItem(
                                                            value: type,
                                                            child: Text(
                                                              type.displayName,
                                                            ),
                                                          );
                                                        })
                                                        .toList(),
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        setState(() {
                                                          _selectedConnectionType =
                                                              val;
                                                        });
                                                      }
                                                    },
                                                  ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child:
                                                  DropdownButtonFormField<
                                                    String
                                                  >(
                                                    initialValue:
                                                        availablePackages.any(
                                                          (p) =>
                                                              p.id ==
                                                              _selectedPackageId,
                                                        )
                                                            ? _selectedPackageId
                                                            : null,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Select Package',
                                                          helperText:
                                                              'Sets the upstream cost used for monthly profit',
                                                        ),
                                                    hint: const Text(
                                                      'Select Package',
                                                    ),
                                                    items: availablePackages.map(
                                                      (pkg) {
                                                        return DropdownMenuItem(
                                                          value: pkg.id,
                                                          child: Text(pkg.name),
                                                        );
                                                      },
                                                    ).toList(),
                                                    onChanged:
                                                        _onPackageChanged,
                                                    // Required: see the mobile
                                                    // variant above.
                                                    validator: (v) =>
                                                        (v == null || v.isEmpty)
                                                            ? 'Select a package — it sets the cost side of profit'
                                                            : null,
                                                  ),
                                            ),
                                          ],
                                        ),
                                  const SizedBox(height: 16),
                                  Responsive.isMobile(context)
                                      ? Column(
                                          children: [
                                            AppFormField(
                                              label: 'Monthly Bill Rate (PKR)',
                                              isRequired: true,
                                              controller:
                                                  _monthlyBillController,
                                              keyboardType:
                                                  const TextInputType
                                                      .numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              inputFormatters:
                                                  AppInputFormatters.decimal,
                                              validator: (v) =>
                                                  ValidationUtils.validateAmount(
                                                    v,
                                                    fieldName: 'Monthly Bill',
                                                  ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: AppFormField(
                                                label:
                                                    'Monthly Bill Rate (PKR)',
                                                isRequired: true,
                                                controller:
                                                    _monthlyBillController,
                                                keyboardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                inputFormatters:
                                                    AppInputFormatters.decimal,
                                                validator: (v) => ValidationUtils
                                                    .validateAmount(
                                                      v,
                                                      fieldName: 'Monthly Bill',
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                  const SizedBox(height: 30),
                                  AdaptiveFormActions(
                                    secondary: OutlinedButton(
                                      onPressed: () {
                                        context.go(RoutePaths.customers);
                                      },
                                      child: const Text("Cancel"),
                                    ),
                                    primary: ElevatedButton.icon(
                                      onPressed: (_isSaving || _isLoadingExisting)
                                          ? null
                                          : _saveForm,
                                      icon: const Icon(Icons.save),
                                      label: Text(
                                        _isSaving
                                            ? "Saving..."
                                            : (_isLoadingExisting
                                                ? "Loading..."
                                                : "Save Configuration"),
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
  }
}
