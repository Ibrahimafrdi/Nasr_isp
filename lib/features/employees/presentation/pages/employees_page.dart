import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/core/utils/input_formatters.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/employees/domain/entities/employee_entity.dart';
import 'package:nasr_isp/features/employees/data/models/employee_model.dart';
import 'package:nasr_isp/features/employees/presentation/bloc/employees_bloc.dart';
import 'package:nasr_isp/features/employees/presentation/widgets/employee_card_list.dart';
import 'package:nasr_isp/features/employees/presentation/widgets/employee_metric_cards.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({Key? key}) : super(key: key);

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final TextEditingController _searchController = TextEditingController();

  // Cached last successfully loaded state, so a transient EmployeeLoading
  // (e.g. while an edit/toggle is saving) or an EmployeeError doesn't blank
  // out or replace an already-visible list.
  EmployeeLoaded? _lastLoaded;

  @override
  void initState() {
    super.initState();
    // Dispatch Load event on page enter
    context.read<EmployeeBloc>().add(const LoadEmployeesEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Returns a copy of [emp] with its status flipped (active <-> inactive).
  EmployeeModel _withToggledStatus(EmployeeEntity emp) {
    final isInactive = emp.status == EmployeeStatus.inactive;
    return EmployeeModel(
      id: emp.id,
      name: emp.name,
      phone: emp.phone,
      email: emp.email,
      address: emp.address,
      designation: emp.designation,
      sectorArea: emp.sectorArea,
      status: isInactive ? EmployeeStatus.active : EmployeeStatus.inactive,
      salary: emp.salary,
      joinDate: emp.joinDate,
      createdAt: emp.createdAt,
    );
  }

  Future<void> _confirmToggleStatus(
    BuildContext context,
    EmployeeEntity emp,
  ) async {
    final isInactive = emp.status == EmployeeStatus.inactive;
    final newStatus = isInactive
        ? EmployeeStatus.active
        : EmployeeStatus.inactive;

    showDialog(
      context: context,
      builder: (dCtx) => ConfirmationDialog(
        title: isInactive ? 'Enable Technician' : 'Disable Technician',
        message: isInactive
            ? 'Re-enable ${emp.name}? They will become assignable to new installations again.'
            : 'Disable ${emp.name}? They will no longer be assignable to new installations.',
        confirmLabel: isInactive ? 'Enable' : 'Disable',
        isDestructive: !isInactive,
        onConfirm: () async {
          Navigator.pop(dCtx);
          final bloc = context.read<EmployeeBloc>();
          bloc.add(UpdateEmployeeEvent(_withToggledStatus(emp)));

          final result = await bloc.stream.firstWhere(
            (s) => s is EmployeeLoaded || s is EmployeeError,
          );

          if (!context.mounted) return;

          if (result is EmployeeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update status: ${result.message}'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Employee status updated to ${newStatus.displayName}',
              ),
              backgroundColor: newStatus == EmployeeStatus.active
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
            ),
          );
        },
        onCancel: () => Navigator.pop(dCtx),
      ),
    );
  }

  void _showAddEditEmployeeDialog(
    BuildContext context, [
    EmployeeEntity? employee,
  ]) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: employee?.name ?? '');
    final phoneController = TextEditingController(
      text: employee != null
          ? AppInputFormatters.formatPhone(employee.phone)
          : '',
    );
    final emailController = TextEditingController(text: employee?.email ?? '');
    final addressController = TextEditingController(
      text: employee?.address ?? '',
    );
    final designationController = TextEditingController(
      text: employee?.designation ?? '',
    );
    final salaryController = TextEditingController(
      text: employee != null ? employee.salary.toStringAsFixed(0) : '',
    );

    String? selectedArea = (employee != null && employee.sectorArea.isNotEmpty)
        ? employee.sectorArea
        : null;
    EmployeeStatus selectedStatus = employee?.status ?? EmployeeStatus.active;
    DateTime joinDate = employee?.joinDate ?? DateTime.now();
    bool isSaving = false;

    final isMobileDialog = Responsive.isMobile(context);
    final dialogTitle = employee == null
        ? 'Add Team Member / Installer'
        : 'Edit Team Member';

    showDialog(
      context: context,
      useSafeArea: !isMobileDialog,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit() async {
              if (formKey.currentState!.validate()) {
                setState(() => isSaving = true);

                final empId = employee?.id ?? const Uuid().v4();
                final updatedModel = EmployeeModel(
                  id: empId,
                  name: nameController.text.trim(),
                  phone: AppInputFormatters.digitsOnly(phoneController.text),
                  email: emailController.text.trim(),
                  address: addressController.text.trim(),
                  designation: designationController.text.trim(),
                  sectorArea: selectedArea ?? '',
                  status: selectedStatus,
                  salary: double.parse(salaryController.text.trim()),
                  joinDate: joinDate,
                  createdAt: employee?.createdAt ?? DateTime.now(),
                );

                final bloc = ctx.read<EmployeeBloc>();
                if (employee == null) {
                  bloc.add(AddEmployeeEvent(updatedModel));
                } else {
                  bloc.add(UpdateEmployeeEvent(updatedModel));
                }

                final result = await bloc.stream.firstWhere(
                  (s) => s is EmployeeLoaded || s is EmployeeError,
                );

                if (!ctx.mounted || !context.mounted) return;

                if (result is EmployeeError) {
                  setState(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save: ${result.message}'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      employee == null
                          ? 'Team member ${updatedModel.name} added successfully!'
                          : 'Team member ${updatedModel.name} updated successfully!',
                    ),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            }

            final formFields = Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Employee Full Name *',
                    ),
                    validator: (v) => ValidationUtils.validateName(v, 'Name'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number *',
                      hintText: '0314 9498314',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: AppInputFormatters.phone,
                    validator: ValidationUtils.validatePhonePk,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: ValidationUtils.validateOptionalEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: designationController,
                    decoration: const InputDecoration(
                      labelText: 'Job Role / Designation *',
                      hintText: 'e.g. Senior Line Technician',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Designation is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedArea,
                    hint: const Text('Select Sector Area'),
                    decoration: const InputDecoration(
                      labelText: 'Assigned Operational Sector Area',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'DHA & Clifton',
                        child: Text('DHA & Clifton'),
                      ),
                      DropdownMenuItem(
                        value: 'Gulshan & Johar',
                        child: Text('Gulshan & Johar'),
                      ),
                      DropdownMenuItem(
                        value: 'Nazimabad & F.B Area',
                        child: Text('Nazimabad & F.B Area'),
                      ),
                      DropdownMenuItem(
                        value: 'Saddar & Tariq Road',
                        child: Text('Saddar & Tariq Road'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedArea = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: salaryController,
                    decoration: const InputDecoration(
                      labelText: 'Salary (PKR) *',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: AppInputFormatters.decimal,
                    validator: (v) =>
                        ValidationUtils.validateAmount(v, fieldName: 'Salary'),
                  ),
                  const SizedBox(height: 16),
                  // Join Date Picker Row
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: joinDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (!context.mounted) return;
                      if (picked != null) {
                        setState(() => joinDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Join Date'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('yyyy-MM-dd').format(joinDate)),
                          const Icon(Icons.calendar_month, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<EmployeeStatus>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: EmployeeStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedStatus = val);
                    },
                  ),
                ],
              ),
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
            final saveLabel = Text(
              isSaving
                  ? 'Saving...'
                  : (employee == null ? 'Add Employee' : 'Save Changes'),
            );

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
                    child: formFields,
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
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(child: formFields),
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

  void _showEmployeeDetailsDialog(
    BuildContext context,
    EmployeeEntity employee,
  ) {
    final isMobileDialog = Responsive.isMobile(context);
    showDialog(
      context: context,
      useSafeArea: !isMobileDialog,
      builder: (ctx) {
        final isInactive = employee.status == EmployeeStatus.inactive;
        final dateFormatted = employee.joinDate != null
            ? DateFormat('dd MMMM yyyy').format(employee.joinDate!)
            : 'Not set';

        void toggleStatus() {
          Navigator.pop(ctx);
          _confirmToggleStatus(context, employee);
        }

        void editProfile() {
          Navigator.pop(ctx);
          _showAddEditEmployeeDialog(context, employee);
        }

        final statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isInactive
                ? AppTheme.errorColor.withOpacity(0.1)
                : AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            employee.status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isInactive ? AppTheme.errorColor : AppTheme.successColor,
            ),
          ),
        );

        final detailsContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      employee.name.isNotEmpty
                          ? employee.name.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    employee.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employee.designation,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mediumGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isMobileDialog) ...[
                    const SizedBox(height: 8),
                    statusBadge,
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            _detailRow(Icons.phone_outlined, 'Contact Phone', employee.phone),
            _detailRow(
              Icons.mail_outline_rounded,
              'Email Address',
              employee.email.isNotEmpty ? employee.email : '—',
            ),
            _detailRow(
              Icons.map_outlined,
              'Operational Sector',
              employee.sectorArea,
            ),
            _detailRow(
              Icons.payments_outlined,
              'Salary',
              'PKR ${employee.salary.toStringAsFixed(0)}',
            ),
            _detailRow(
              Icons.calendar_today_outlined,
              'Join Date',
              dateFormatted,
            ),
            _detailRow(
              Icons.home_work_outlined,
              'Address',
              employee.address.isNotEmpty ? employee.address : '—',
            ),
          ],
        );

        final toggleButton = ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isInactive
                ? AppTheme.successColor
                : AppTheme.errorColor,
            foregroundColor: Colors.white,
          ),
          onPressed: toggleStatus,
          icon: Icon(
            isInactive ? Icons.check_circle_outline : Icons.block,
            size: 16,
          ),
          label: Text(isInactive ? 'Enable Tech' : 'Disable Tech'),
        );
        final editButton = ElevatedButton.icon(
          onPressed: editProfile,
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Edit Profile'),
        );

        if (isMobileDialog) {
          return Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Employee Profile'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: detailsContent,
              ),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: double.infinity, child: editButton),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: toggleButton),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('Employee Profile'), statusBadge],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(child: detailsContent),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            toggleButton,
            editButton,
          ],
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mediumGray,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // HOW TO USE THIS FILE
  // In lib/features/employees/presentation/pages/employees_page.dart:
  //   1. Keep the imports and everything above `@override Widget build`
  //      (the add/edit dialog, the details dialog, _detailRow, toggle logic).
  //   2. Delete from
  //         @override
  //         Widget build(BuildContext context) {
  //           final isMobile = Responsive.isMobile(context);
  //      down to the END of the file (including the last `}` of the class).
  //   3. Paste everything below this comment block. Its last `}` closes the
  //      class.
  // ════════════════════════════════════════════════════════════════════════

  static const _accent = Color(0xFF0F766E);
  static const _ink = Color(0xFF14213D);
  static const _muted = Color(0xFF5B6472);
  static const _border = Color(0xFFE3E6EB);
  static const _line = Color(0xFFC9CED6);

  /// null = show everyone.
  EmployeeStatus? _statusFilter;

  Widget _pill(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? _accent : Colors.white,
      shape: StadiumBorder(side: BorderSide(color: selected ? _accent : _line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : _ink,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: Text('Not authenticated')));
        }

        final isAdmin = authState.user.isAdmin;

        return Scaffold(
          body: BlocConsumer<EmployeeBloc, EmployeeState>(
            listener: (context, state) {
              if (state is EmployeeLoaded) {
                _lastLoaded = state;
              } else if (state is EmployeeError && _lastLoaded != null) {
                // Keep the existing list on screen; just surface the failure.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            builder: (context, state) {
              // Prefer the freshly-loaded state; otherwise fall back to the
              // last successfully loaded list rather than blanking the page
              // during a transient reload or a failed add/update/toggle.
              final displayState = state is EmployeeLoaded
                  ? state
                  : _lastLoaded;

              if (displayState == null) {
                if (state is EmployeeError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.message,
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<EmployeeBloc>().add(
                            const LoadEmployeesEvent(),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              }

              final employeesList = displayState.employees;
              final activeTechs = employeesList
                  .where((e) => e.status == EmployeeStatus.active)
                  .toList();

              // Subscribers count maps to installations (active techs only).
              int totalSubsAssigned = 0;
              displayState.installationCounts.forEach((empId, count) {
                final isEmpActive = employeesList.any(
                  (emp) =>
                      emp.id == empId && emp.status == EmployeeStatus.active,
                );
                if (isEmpActive) totalSubsAssigned += count;
              });

              final shown = _statusFilter == null
                  ? employeesList
                  : employeesList
                        .where((e) => e.status == _statusFilter)
                        .toList();

              final search = TextField(
                controller: _searchController,
                onChanged: (query) {
                  setState(() {});
                  context.read<EmployeeBloc>().add(SearchEmployeesEvent(query));
                },
                decoration: InputDecoration(
                  hintText: 'Search name, phone or area',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            context.read<EmployeeBloc>().add(
                              const SearchEmployeesEvent(''),
                            );
                            setState(() {});
                          },
                        ),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _line),
                  ),
                ),
              );

              final pills = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(
                    'All',
                    _statusFilter == null,
                    () => setState(() => _statusFilter = null),
                  ),
                  _pill(
                    'Active',
                    _statusFilter == EmployeeStatus.active,
                    () => setState(() => _statusFilter = EmployeeStatus.active),
                  ),
                  _pill(
                    'Disabled',
                    _statusFilter == EmployeeStatus.inactive,
                    () =>
                        setState(() => _statusFilter = EmployeeStatus.inactive),
                  ),
                ],
              );

              return SingleChildScrollView(
                padding: Responsive.pagePaddingFor(
                  Responsive.deviceTypeOf(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Header ──────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Employees',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Your field team and the work assigned to them.',
                                style: TextStyle(fontSize: 14, color: _muted),
                              ),
                            ],
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showAddEditEmployeeDialog(context),
                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                            label: Text(isMobile ? 'Add' : 'Add technician'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Summary ─────────────────────────────────────────
                    EmployeeMetricCards(
                      totalCount: employeesList.length,
                      activeCount: activeTechs.length,
                      totalSubsAssigned: totalSubsAssigned,
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 24),

                    // ─── Search + status filter in one row ───────────────
                    LayoutBuilder(
                      builder: (context, c) {
                        if (c.maxWidth >= 700) {
                          return Row(
                            children: [
                              SizedBox(width: 320, child: search),
                              const SizedBox(width: 16),
                              Expanded(child: pills),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [search, const SizedBox(height: 12), pills],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // ─── List ────────────────────────────────────────────
                    _buildEmployeeList(
                      shown,
                      displayState.installationCounts,
                      isMobile: isMobile,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─── List (table on desktop, cards on mobile) ──────────────────────────────

  Widget _buildEmployeeList(
    List<EmployeeEntity> employees,
    Map<String, int> installationCounts, {
    required bool isMobile,
  }) {
    if (employees.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: const Center(
          child: Text('No employees found.', style: TextStyle(color: _muted)),
        ),
      );
    }

    if (isMobile) {
      return EmployeeCardList(
        employees: employees,
        installationCounts: installationCounts,
        onViewDetail: (emp) => _showEmployeeDetailsDialog(context, emp),
        onEdit: (emp) => _showAddEditEmployeeDialog(context, emp),
        onToggleStatus: (emp) => _confirmToggleStatus(context, emp),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildEmployeesTable(employees, installationCounts),
    );
  }

  static const _flex = [26, 18, 16, 14, 10, 16];

  Widget _headerCell(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: _muted,
    ),
  );

  Widget _tableRow(List<Widget> cells, {bool last = false}) {
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
              flex: _flex[i],
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: cells[i],
              ),
            ),
        ],
      ),
    );
  }

  /// Desktop table: fills the full width.
  Widget _buildEmployeesTable(
    List<EmployeeEntity> employees,
    Map<String, int> installationCounts,
  ) {
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth < 860 ? 860.0 : c.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                _tableRow([
                  _headerCell('Name'),
                  _headerCell('Sector area'),
                  _headerCell('Contact'),
                  _headerCell('Subscribers assigned'),
                  _headerCell('Status'),
                  _headerCell('Actions'),
                ]),
                for (var i = 0; i < employees.length; i++)
                  _employeeRow(
                    employees[i],
                    installationCounts[employees[i].id] ?? 0,
                    last: i == employees.length - 1,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _employeeRow(EmployeeEntity emp, int subs, {required bool last}) {
    final isInactive = emp.status == EmployeeStatus.inactive;
    final statusColor = isInactive
        ? AppTheme.errorColor
        : AppTheme.successColor;

    return _tableRow([
      InkWell(
        onTap: () => _showEmployeeDetailsDialog(context, emp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emp.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color.fromARGB(255, 8, 14, 28),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              emp.designation,
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ),
      ),
      Text(
        emp.sectorArea.isEmpty ? '—' : emp.sectorArea,
        style: const TextStyle(fontSize: 14, color: _ink),
      ),
      Text(
        AppInputFormatters.formatPhone(emp.phone),
        style: const TextStyle(fontSize: 14, color: _ink),
      ),
      Text('$subs', style: const TextStyle(fontSize: 14, color: _ink)),
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            emp.status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      ),
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
            onPressed: () => _showAddEditEmployeeDialog(context, emp),
            child: const Text('Edit'),
          ),
          PopupMenuButton<String>(
            tooltip: 'More actions',
            icon: const Icon(Icons.more_horiz),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onSelected: (v) {
              if (v == 'view') _showEmployeeDetailsDialog(context, emp);
              if (v == 'toggle') _confirmToggleStatus(context, emp);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Text('View profile')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(
                  isInactive ? 'Enable technician' : 'Disable technician',
                  style: TextStyle(
                    color: isInactive ? null : AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ], last: last);
  }
}
