import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';

class AddCustomerPage extends StatefulWidget {
  final String? customerId;

  const AddCustomerPage({Key? key, this.customerId}) : super(key: key);

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _rateController;

  String _selectedPackage = '10 Mbps';
  String _selectedEmployee = 'emp_1';
  bool _isSaving = false;

  final List<String> _packages = ['10 Mbps', '25 Mbps', '50 Mbps', '100 Mbps'];
  final Map<String, double> _packageRates = {
    '10 Mbps': 999.0,
    '25 Mbps': 1499.0,
    '50 Mbps': 2499.0,
    '100 Mbps': 4499.0,
  };

  final List<Map<String, String>> _employees = [
    {'id': 'emp_1', 'name': 'Technician Ali'},
    {'id': 'emp_2', 'name': 'Technician Hamza'},
    {'id': 'emp_3', 'name': 'Technician Sana'},
    {'id': 'emp_4', 'name': 'Technician Bilal'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _rateController = TextEditingController(
      text: _packageRates[_selectedPackage].toString(),
    );

    if (widget.customerId != null) {
      // Simulate fetching existing customer details for Edit Mode
      _nameController.text =
          'Customer ${widget.customerId!.replaceAll('cust_', '')}';
      _phoneController.text = '+923001234567';
      _emailController.text = 'subscriber@nasr_isp.com';
      _addressController.text = 'Flat 402, Block D, Gulshan, Karachi';
      _selectedPackage = '25 Mbps';
      _rateController.text = _packageRates[_selectedPackage].toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _onPackageChanged(String? newPackage) {
    if (newPackage != null) {
      setState(() {
        _selectedPackage = newPackage;
        _rateController.text = _packageRates[newPackage].toString();
      });
    }
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      // Simulate network save delay
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      final newCustomer = CustomerModel(
        id: widget.customerId ?? 'cust_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        packageName: _selectedPackage,
        monthlyRate: double.tryParse(_rateController.text) ?? 0.0,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        status: CustomerStatus.active,
        assignedEmployeeId: _selectedEmployee,
        createdAt: DateTime.now(),
        balance: 0.0,
      );

      if (widget.customerId == null) {
        context.read<CustomersBloc>().add(CreateCustomerEvent(newCustomer));
      } else {
        context.read<CustomersBloc>().add(UpdateCustomerEvent(newCustomer));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.customerId == null
                ? 'Subscriber account created successfully!'
                : 'Subscriber details updated successfully!',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.go(RoutePaths.customers);
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

        return Padding(
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
                    label: isEditMode ? 'Modify Profile' : 'New Subscription',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                isEditMode ? 'Edit Account' : 'Provisioning Form',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: AppTheme.lightGray.withOpacity(0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Information',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: AppFormField(
                                    label: 'Full Name',
                                    isRequired: true,
                                    controller: _nameController,
                                    hintText: 'Enter complete name',
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                        ? 'Name is required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppFormField(
                                    label: 'Phone Number',
                                    isRequired: true,
                                    controller: _phoneController,
                                    hintText: '+923001234567',
                                    keyboardType: TextInputType.phone,
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                        ? 'Phone is required'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: AppFormField(
                                    label: 'Email Address',
                                    controller: _emailController,
                                    hintText: 'name@nasr.com',
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Assigned Field Technician',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: _selectedEmployee,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                        items: _employees.map((emp) {
                                          return DropdownMenuItem<String>(
                                            value: emp['id'],
                                            child: Text(emp['name']!),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _selectedEmployee = val,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            AppFormField(
                              label: 'Installation Physical Address',
                              isRequired: true,
                              controller: _addressController,
                              hintText:
                                  'Enter complete flat, street, block and area detail...',
                              maxLines: 2,
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Address is required'
                                  : null,
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Plan & Subscription Service',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Bandwidth Plan',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: _selectedPackage,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                        items: _packages.map((pkg) {
                                          return DropdownMenuItem<String>(
                                            value: pkg,
                                            child: Text(pkg),
                                          );
                                        }).toList(),
                                        onChanged: _onPackageChanged,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppFormField(
                                    label: 'Monthly Rate (PKR)',
                                    isRequired: true,
                                    controller: _rateController,
                                    keyboardType: TextInputType.number,
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                        ? 'Rate is required'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () =>
                                      context.go(RoutePaths.customers),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: _isSaving ? null : _saveForm,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  label: Text(
                                    _isSaving
                                        ? 'Saving...'
                                        : 'Save Configuration',
                                  ),
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
        );
      },
    );
  }
}
