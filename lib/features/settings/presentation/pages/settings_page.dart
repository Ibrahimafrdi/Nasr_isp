import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/config/service_locator.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/settings/domain/entities/app_settings_entity.dart';
import 'package:nasr_isp/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:nasr_isp/features/settings/presentation/bloc/user_management_bloc.dart';
import 'package:nasr_isp/features/auth/data/models/user_model.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';
import 'package:nasr_isp/shared/widgets/premium_data_table.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (context) => getIt<SettingsBloc>()..add(const LoadSettingsEvent()),
        ),
        BlocProvider<UserManagementBloc>(
          create: (context) => getIt<UserManagementBloc>()..add(const LoadUsersEvent()),
        ),
      ],
      child: const SettingsPageContent(),
    );
  }
}

class SettingsPageContent extends StatefulWidget {
  const SettingsPageContent({Key? key}) : super(key: key);

  @override
  State<SettingsPageContent> createState() => _SettingsPageContentState();
}

class _SettingsPageContentState extends State<SettingsPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _generalFormKey = GlobalKey<FormState>();

  // Text Controllers for App Settings
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _currencySymbolController = TextEditingController();
  final _dueReminderDaysController = TextEditingController();
  final _lateFeeAmountController = TextEditingController();
  final _invoicePrefixController = TextEditingController();

  bool _isSettingsInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _currencySymbolController.dispose();
    _dueReminderDaysController.dispose();
    _lateFeeAmountController.dispose();
    _invoicePrefixController.dispose();
    super.dispose();
  }

  void _initSettingsFields(AppSettingsEntity settings) {
    if (_isSettingsInitialized) return;
    _companyNameController.text = settings.companyName;
    _companyAddressController.text = settings.companyAddress;
    _companyPhoneController.text = settings.companyPhone;
    _companyEmailController.text = settings.companyEmail;
    _currencySymbolController.text = settings.currencySymbol;
    _dueReminderDaysController.text = settings.dueReminderDays.toString();
    _lateFeeAmountController.text = settings.lateFeeAmount.toString();
    _invoicePrefixController.text = settings.invoicePrefix;
    _isSettingsInitialized = true;
  }

  void _saveSettings(BuildContext context) {
    if (!(_generalFormKey.currentState?.validate() ?? false)) return;

    final updatedSettings = AppSettingsEntity(
      companyName: _companyNameController.text.trim(),
      companyAddress: _companyAddressController.text.trim(),
      companyPhone: _companyPhoneController.text.trim(),
      companyEmail: _companyEmailController.text.trim(),
      currencySymbol: _currencySymbolController.text.trim(),
      dueReminderDays: int.tryParse(_dueReminderDaysController.text.trim()) ?? 5,
      lateFeeAmount: double.tryParse(_lateFeeAmountController.text.trim()) ?? 0.0,
      invoicePrefix: _invoicePrefixController.text.trim(),
    );

    context.read<SettingsBloc>().add(SaveSettingsEvent(updatedSettings));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: MultiBlocListener(
        listeners: [
          BlocListener<SettingsBloc, SettingsState>(
            listener: (context, state) {
              if (state is SettingsLoaded) {
                _initSettingsFields(state.settings);
              } else if (state is SettingsSaved) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('App Settings saved successfully.'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              } else if (state is SettingsError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            },
          ),
          BlocListener<UserManagementBloc, UserManagementState>(
            listener: (context, state) {
              if (state is UserManagementSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              } else if (state is UserManagementError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            },
          ),
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Breadcrumb(
                items: [
                  BreadcrumbItem(
                    label: 'Home',
                    onTap: () => context.go('/dashboard'),
                  ),
                  BreadcrumbItem(label: 'Settings'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Administrative Control Panel',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage app configuration and configure authorization credentials.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 24),
              // Beautiful Premium Tabs Header
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.lightGray,
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppColors.primaryBlue,
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: AppColors.darkGray,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.business_center_outlined),
                          SizedBox(width: 8),
                          Text('General Settings'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline_rounded),
                          SizedBox(width: 8),
                          Text('User Management'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Tab Body Area
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return IndexedStack(
                    index: _tabController.index,
                    children: [
                      _buildGeneralTab(),
                      _buildUserManagementTab(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralTab() {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        if (state is SettingsLoading || state is SettingsInitial) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: LoadingWidget(message: 'Loading App Settings...'),
            ),
          );
        }

        final isSaving = state is SettingsSaving;

        return Form(
          key: _generalFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Information Section Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.lightGray),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.apartment_rounded, color: AppColors.primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Company Information',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                          ),
                        ],
                      ),
                      const Divider(height: 32, color: AppColors.lightGray),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          return Column(
                            children: [
                              if (isWide)
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppFormField(
                                        label: 'Company Name',
                                        controller: _companyNameController,
                                        isRequired: true,
                                        validator: (val) => ValidationUtils.validateRequired(val, 'Company Name'),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: AppFormField(
                                        label: 'Helpline / Phone',
                                        controller: _companyPhoneController,
                                        isRequired: true,
                                        validator: (val) => ValidationUtils.validateRequired(val, 'Helpline'),
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                AppFormField(
                                  label: 'Company Name',
                                  controller: _companyNameController,
                                  isRequired: true,
                                  validator: (val) => ValidationUtils.validateRequired(val, 'Company Name'),
                                ),
                                const SizedBox(height: 20),
                                AppFormField(
                                  label: 'Helpline / Phone',
                                  controller: _companyPhoneController,
                                  isRequired: true,
                                  validator: (val) => ValidationUtils.validateRequired(val, 'Helpline'),
                                ),
                              ],
                              const SizedBox(height: 20),
                              if (isWide)
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppFormField(
                                        label: 'Support Email',
                                        controller: _companyEmailController,
                                        isRequired: true,
                                        validator: (val) => ValidationUtils.validateEmail(val),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: AppFormField(
                                        label: 'Company Address',
                                        controller: _companyAddressController,
                                        isRequired: true,
                                        validator: (val) => ValidationUtils.validateRequired(val, 'Address'),
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                AppFormField(
                                  label: 'Support Email',
                                  controller: _companyEmailController,
                                  isRequired: true,
                                  validator: (val) => ValidationUtils.validateEmail(val),
                                ),
                                const SizedBox(height: 20),
                                AppFormField(
                                  label: 'Company Address',
                                  controller: _companyAddressController,
                                  isRequired: true,
                                  validator: (val) => ValidationUtils.validateRequired(val, 'Address'),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // System Preferences Section Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.lightGray),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.settings_suggest_rounded, color: AppColors.primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            'System Preferences',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                          ),
                        ],
                      ),
                      const Divider(height: 32, color: AppColors.lightGray),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          return Column(
                            children: [
                              if (isWide)
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppFormField(
                                        label: 'Currency Symbol',
                                        controller: _currencySymbolController,
                                        isRequired: true,
                                        validator: (val) => ValidationUtils.validateRequired(val, 'Currency'),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: AppFormField(
                                        label: 'Due Reminder (Days before)',
                                        controller: _dueReminderDaysController,
                                        isRequired: true,
                                        keyboardType: TextInputType.number,
                                        validator: (val) {
                                          if (val == null || val.isEmpty) return 'Reminder Days is required';
                                          if (int.tryParse(val) == null) return 'Must be a valid integer';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                AppFormField(
                                  label: 'Currency Symbol',
                                  controller: _currencySymbolController,
                                  isRequired: true,
                                  validator: (val) => ValidationUtils.validateRequired(val, 'Currency'),
                                ),
                                const SizedBox(height: 20),
                                AppFormField(
                                  label: 'Due Reminder (Days before)',
                                  controller: _dueReminderDaysController,
                                  isRequired: true,
                                  keyboardType: TextInputType.number,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'Reminder Days is required';
                                    if (int.tryParse(val) == null) return 'Must be a valid integer';
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 20),
                              if (isWide)
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppFormField(
                                        label: 'Late Fee Amount',
                                        controller: _lateFeeAmountController,
                                        isRequired: true,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) return 'Late fee is required';
                                          if (double.tryParse(val) == null) return 'Must be a valid decimal';
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: AppFormField(
                                        label: 'Invoice Number Prefix',
                                        controller: _invoicePrefixController,
                                        isRequired: true,
                                        validator: (val) => ValidationUtils.validateRequired(val, 'Invoice Prefix'),
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                AppFormField(
                                  label: 'Late Fee Amount',
                                  controller: _lateFeeAmountController,
                                  isRequired: true,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'Late fee is required';
                                    if (double.tryParse(val) == null) return 'Must be a valid decimal';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                AppFormField(
                                  label: 'Invoice Number Prefix',
                                  controller: _invoicePrefixController,
                                  isRequired: true,
                                  validator: (val) => ValidationUtils.validateRequired(val, 'Invoice Prefix'),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Action Save Button
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : () => _saveSettings(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      isSaving ? 'Saving Settings...' : 'Save Settings',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildUserManagementTab() {
    return BlocBuilder<UserManagementBloc, UserManagementState>(
      builder: (context, state) {
        if (state is UserManagementLoading || state is UserManagementInitial) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: LoadingWidget(message: 'Loading Users...'),
            ),
          );
        }

        final authState = context.watch<AuthBloc>().state;
        final currentUser = authState is AuthAuthenticated ? authState.user : null;

        List<UserModel> users = [];
        if (state is UserManagementLoaded) {
          users = state.users;
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.lightGray),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'System Access Accounts',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddUserDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add User'),
                    ),
                  ],
                ),
                const Divider(height: 32, color: AppColors.lightGray),
                if (users.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: Text('No auth users found in system.'),
                    ),
                  )
                else
                  PremiumDataTable(
                    columns: [
                      PremiumDataColumn(label: 'Name'),
                      PremiumDataColumn(label: 'Email'),
                      PremiumDataColumn(label: 'Role'),
                      PremiumDataColumn(label: 'Status'),
                      PremiumDataColumn(label: 'Actions'),
                    ],
                    rows: users.map((user) {
                      final isSelf = currentUser?.id == user.id;

                      return PremiumDataRow(
                        cells: [
                          Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(user.email),
                          // Role Dropdown Cell
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: user.role == 'admin' ? 'admin' : 'employee',
                              items: const [
                                DropdownMenuItem(
                                  value: 'admin',
                                  child: Text('Admin'),
                                ),
                                DropdownMenuItem(
                                  value: 'employee',
                                  child: Text('Employee'),
                                ),
                              ],
                              onChanged: (newRole) {
                                if (newRole != null && newRole != user.role) {
                                  context.read<UserManagementBloc>().add(
                                        UpdateUserRoleEvent(
                                          uid: user.id,
                                          role: newRole,
                                        ),
                                      );
                                }
                              },
                            ),
                          ),
                          // Status Badge + Text cell
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: user.isActive
                                      ? AppColors.successGreen
                                      : AppColors.errorRed,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(user.isActive ? 'Active' : 'Inactive'),
                            ],
                          ),
                          // Switch / Actions Cell
                          Switch(
                            value: user.isActive,
                            activeThumbColor: AppColors.successGreen,
                            onChanged: isSelf
                                ? null // Disable self deactivation
                                : (value) {
                                    context.read<UserManagementBloc>().add(
                                          ToggleUserStatusEvent(
                                            uid: user.id,
                                            isActive: value,
                                          ),
                                        );
                                  },
                          ),
                        ],
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'employee';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stContext, setState) {
            return AlertDialog(
              title: const Text('Add User Account'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppFormField(
                        label: 'Name',
                        controller: nameController,
                        isRequired: true,
                        validator: (val) => ValidationUtils.validateRequired(val, 'Name'),
                      ),
                      const SizedBox(height: 16),
                      AppFormField(
                        label: 'Email',
                        controller: emailController,
                        isRequired: true,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) => ValidationUtils.validateEmail(val),
                      ),
                      const SizedBox(height: 16),
                      AppFormField(
                        label: 'Password',
                        controller: passwordController,
                        isRequired: true,
                        isPassword: true,
                        validator: (val) => ValidationUtils.validatePassword(val),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Role',
                          style: Theme.of(dialogContext).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem(
                            value: 'employee',
                            child: Text('Employee'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedRole = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      context.read<UserManagementBloc>().add(
                            CreateUserEvent(
                              name: nameController.text.trim(),
                              email: emailController.text.trim(),
                              password: passwordController.text,
                              role: selectedRole,
                            ),
                          );
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Create User'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}