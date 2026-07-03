import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/employees/domain/entities/employee_entity.dart';
import 'package:nasr_isp/features/employees/data/models/employee_model.dart';
import 'package:nasr_isp/features/employees/presentation/bloc/employees_bloc.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/responsive_dashboard.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({Key? key}) : super(key: key);

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final TextEditingController _searchController = TextEditingController();

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

  void _showAddEditEmployeeDialog(BuildContext context, [EmployeeEntity? employee]) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: employee?.name ?? '');
    final phoneController = TextEditingController(text: employee?.phone ?? '');
    final emailController = TextEditingController(text: employee?.email ?? '');
    final addressController = TextEditingController(text: employee?.address ?? '');
    final designationController = TextEditingController(text: employee?.designation ?? '');
    final salaryController = TextEditingController(
      text: employee != null ? employee.salary.toStringAsFixed(0) : '',
    );
    
    String selectedArea = employee?.sectorArea ?? 'DHA & Clifton';
    EmployeeStatus selectedStatus = employee?.status ?? EmployeeStatus.active;
    DateTime joinDate = employee?.joinDate ?? DateTime.now();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(employee == null ? 'Add Team Member / Installer' : 'Edit Team Member'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Employee Full Name *',
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Contact Number *',
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Phone is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                              if (!emailRegex.hasMatch(v.trim())) {
                                return 'Invalid email format';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: designationController,
                          decoration: const InputDecoration(
                            labelText: 'Job Role / Designation *',
                            hintText: 'e.g. Senior Line Technician',
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Designation is required' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedArea,
                          decoration: const InputDecoration(
                            labelText: 'Assigned Operational Sector Area',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'DHA & Clifton', child: Text('DHA & Clifton')),
                            DropdownMenuItem(value: 'Gulshan & Johar', child: Text('Gulshan & Johar')),
                            DropdownMenuItem(value: 'Nazimabad & F.B Area', child: Text('Nazimabad & F.B Area')),
                            DropdownMenuItem(value: 'Saddar & Tariq Road', child: Text('Saddar & Tariq Road')),
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Salary is required';
                            if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                            return null;
                          },
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
                            if (picked != null) {
                              setState(() => joinDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Join Date',
                            ),
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
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
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
                      : () {
                          if (formKey.currentState!.validate()) {
                            setState(() => isSaving = true);
                            
                            final empId = employee?.id ?? 'emp_${DateTime.now().millisecondsSinceEpoch}';
                            final updatedModel = EmployeeModel(
                              id: empId,
                              name: nameController.text.trim(),
                              phone: phoneController.text.trim(),
                              email: emailController.text.trim(),
                              address: addressController.text.trim(),
                              designation: designationController.text.trim(),
                              sectorArea: selectedArea,
                              status: selectedStatus,
                              salary: double.parse(salaryController.text.trim()),
                              joinDate: joinDate,
                              createdAt: employee?.createdAt ?? DateTime.now(),
                            );

                            if (employee == null) {
                              ctx.read<EmployeeBloc>().add(AddEmployeeEvent(updatedModel));
                            } else {
                              ctx.read<EmployeeBloc>().add(UpdateEmployeeEvent(updatedModel));
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
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: Text(isSaving ? 'Saving...' : (employee == null ? 'Add Employee' : 'Save Changes')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEmployeeDetailsDialog(BuildContext context, EmployeeEntity employee) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isInactive = employee.status == EmployeeStatus.inactive;
        final dateFormatted = employee.joinDate != null 
            ? DateFormat('dd MMMM yyyy').format(employee.joinDate!) 
            : 'Not set';

        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Employee Profile'),
              Container(
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
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: Text(
                            employee.name.substring(0, 1).toUpperCase(),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  _detailRow(Icons.phone_outlined, 'Contact Phone', employee.phone),
                  _detailRow(Icons.mail_outline_rounded, 'Email Address', employee.email.isNotEmpty ? employee.email : '—'),
                  _detailRow(Icons.map_outlined, 'Operational Sector', employee.sectorArea),
                  _detailRow(Icons.payments_outlined, 'Salary', 'PKR ${employee.salary.toStringAsFixed(0)}'),
                  _detailRow(Icons.calendar_today_outlined, 'Join Date', dateFormatted),
                  _detailRow(Icons.home_work_outlined, 'Address', employee.address.isNotEmpty ? employee.address : '—'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isInactive ? AppTheme.successColor : AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final newStatus = isInactive ? EmployeeStatus.active : EmployeeStatus.inactive;
                final updatedModel = EmployeeModel(
                  id: employee.id,
                  name: employee.name,
                  phone: employee.phone,
                  email: employee.email,
                  address: employee.address,
                  designation: employee.designation,
                  sectorArea: employee.sectorArea,
                  status: newStatus,
                  salary: employee.salary,
                  joinDate: employee.joinDate,
                  createdAt: employee.createdAt,
                );

                ctx.read<EmployeeBloc>().add(UpdateEmployeeEvent(updatedModel));
                Navigator.pop(ctx);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Employee status updated to ${newStatus.displayName}'),
                    backgroundColor: newStatus == EmployeeStatus.active ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                );
              },
              icon: Icon(isInactive ? Icons.check_circle_outline : Icons.block, size: 16),
              label: Text(isInactive ? 'Enable Tech' : 'Disable Tech'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showAddEditEmployeeDialog(context, employee);
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit Profile'),
            ),
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

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveDashboard.isMobile(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: Text('Not authenticated')));
        }

        final isAdmin = authState.user.isAdmin;

        return Scaffold(
          body: BlocBuilder<EmployeeBloc, EmployeeState>(
            builder: (context, state) {
              if (state is EmployeeInitial || state is EmployeeLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is EmployeeError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.message,
                        style: const TextStyle(color: AppTheme.errorColor, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<EmployeeBloc>().add(const LoadEmployeesEvent()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is EmployeeLoaded) {
                final employeesList = state.employees;
                final activeTechs = employeesList.where((e) => e.status == EmployeeStatus.active).toList();
                
                // Subscribers count maps to installations
                int totalSubsAssigned = 0;
                state.installationCounts.forEach((empId, count) {
                  // Only count installations of active technicians
                  final isEmpActive = employeesList.any((emp) => emp.id == empId && emp.status == EmployeeStatus.active);
                  if (isEmpActive) {
                    totalSubsAssigned += count;
                  }
                });

                return SingleChildScrollView(
                  padding: EdgeInsets.all(
                    isMobile ? AppConstants.paddingMedium : AppConstants.paddingLarge,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Header ────────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Breadcrumb(
                              items: [
                                BreadcrumbItem(
                                  label: 'Home',
                                  onTap: () => context.go(RoutePaths.dashboard),
                                ),
                                BreadcrumbItem(label: 'Employees'),
                              ],
                            ),
                          ),
                          if (isAdmin)
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditEmployeeDialog(context),
                              icon: const Icon(Icons.person_add_alt_1, size: 18),
                              label: Text(isMobile ? 'Add' : 'Add Technician'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ─── Metric Cards ──────────────────────────────────────
                      _buildMetricCards(
                        employeesList.length,
                        activeTechs.length,
                        totalSubsAssigned,
                        isMobile,
                      ),
                      const SizedBox(height: 28),

                      // Search bar
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search, color: AppColors.mediumGray),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        decoration: const InputDecoration(
                                          hintText: 'Search by Name, Contact, Sector operational area or Designation...',
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          fillColor: Colors.transparent,
                                          filled: false,
                                        ),
                                        onChanged: (query) {
                                          context.read<EmployeeBloc>().add(SearchEmployeesEvent(query));
                                        },
                                      ),
                                    ),
                                    if (_searchController.text.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          context.read<EmployeeBloc>().add(const SearchEmployeesEvent(''));
                                          setState(() {});
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ─── Main Body ─────────────────────────────────────────
                      ResponsiveDashboard(
                        mobile: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEmployeeTableCard(employeesList, state.installationCounts, isMobile: true),
                            const SizedBox(height: 24),
                            _buildTeamActivityCard(),
                          ],
                        ),
                        desktop: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildEmployeeTableCard(employeesList, state.installationCounts, isMobile: false),
                            ),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: _buildTeamActivityCard()),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox();
            },
          ),
        );
      },
    );
  }

  // ─── Metric Cards ──────────────────────────────────────────────────────────

  Widget _buildMetricCards(
    int totalCount,
    int activeCount,
    int totalSubsAssigned,
    bool isMobile,
  ) {
    final double avgSubs = activeCount > 0 ? (totalSubsAssigned / activeCount) : 0.0;

    final cards = [
      DashboardCard(
        label: 'Total Field Personnel',
        value: activeCount.toString(),
        icon: Icons.groups_outlined,
        subtitle: 'Out of $totalCount total registered',
      ),
      DashboardCard(
        label: 'Subscribers Assigned',
        value: totalSubsAssigned.toString(),
        icon: Icons.supervised_user_circle_outlined,
        subtitle: '${avgSubs.toStringAsFixed(0)} avg/tech (active only)',
      ),
      DashboardCard(
        label: 'Avg Billing Efficiency',
        value: '—',
        icon: Icons.assignment_turned_in_outlined,
        backgroundColor: Colors.white,
        subtitle: 'Attribution feature coming soon',
        // TODO: Wire to real collection-efficiency data once payment-to-employee
        // attribution exists. Currently no field links a Payment to the employee
        // who collected it. Do not fabricate this number from unrelated data.
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          cards[2],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
        const SizedBox(width: 16),
        Expanded(child: cards[2]),
      ],
    );
  }

  // ─── Employee Table Card ───────────────────────────────────────────────────

  Widget _buildEmployeeTableCard(
    List<EmployeeEntity> employees,
    Map<String, int> installationCounts, {
    required bool isMobile,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Field Personnel Directory',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (employees.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No employees found.',
                    style: TextStyle(color: AppColors.mediumGray),
                  ),
                ),
              )
            else
              isMobile
                  ? _buildEmployeeCardList(employees, installationCounts)
                  : _buildEmployeesTable(employees, installationCounts),
          ],
        ),
      ),
    );
  }

  /// Mobile: Card list
  Widget _buildEmployeeCardList(List<EmployeeEntity> employees, Map<String, int> installationCounts) {
    return Column(
      children: employees.map((emp) {
        final subs = installationCounts[emp.id] ?? 0;
        final isInactive = emp.status == EmployeeStatus.inactive;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.veryLightGray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => _showEmployeeDetailsDialog(context, emp),
                    child: Text(
                      emp.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isInactive 
                          ? AppTheme.errorColor.withOpacity(0.1) 
                          : AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      emp.status.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isInactive ? AppTheme.errorColor : AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                emp.designation,
                style: const TextStyle(fontSize: 12, color: AppTheme.mediumGray),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _infoChip(Icons.location_on, emp.sectorArea),
                  _infoChip(Icons.phone, emp.phone),
                  _infoChip(Icons.people, '$subs assigned'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: AppTheme.primaryColor),
                    onPressed: () => _showAddEditEmployeeDialog(context, emp),
                  ),
                  IconButton(
                    icon: Icon(
                      isInactive ? Icons.check_circle_outline : Icons.block,
                      size: 18,
                      color: isInactive ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                    onPressed: () {
                      final updated = EmployeeModel(
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
                      context.read<EmployeeBloc>().add(UpdateEmployeeEvent(updated));
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.mediumGray),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.mediumGray),
        ),
      ],
    );
  }

  /// Desktop: DataTable
  Widget _buildEmployeesTable(List<EmployeeEntity> employees, Map<String, int> installationCounts) {
    return DataTableWrapper(
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Designation')),
        DataColumn(label: Text('Sector Area')),
        DataColumn(label: Text('Contact')),
        DataColumn(label: Text('Assigned Subscribers')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: employees.map((emp) {
        final subs = installationCounts[emp.id] ?? 0;
        final isInactive = emp.status == EmployeeStatus.inactive;

        return DataRow(
          cells: [
            DataCell(
              InkWell(
                onTap: () => _showEmployeeDetailsDialog(context, emp),
                child: Text(
                  emp.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            DataCell(Text(emp.designation)),
            DataCell(Text(emp.sectorArea)),
            DataCell(Text(emp.phone)),
            DataCell(Text(subs.toString())),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isInactive
                      ? AppTheme.errorColor.withOpacity(0.1)
                      : AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  emp.status.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isInactive ? AppTheme.errorColor : AppTheme.successColor,
                  ),
                ),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: AppTheme.primaryColor),
                    tooltip: 'Edit Profile',
                    onPressed: () => _showAddEditEmployeeDialog(context, emp),
                  ),
                  IconButton(
                    icon: Icon(
                      isInactive ? Icons.check_circle_outline : Icons.block,
                      size: 18,
                      color: isInactive ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                    tooltip: isInactive ? 'Enable Employee' : 'Disable Employee',
                    onPressed: () {
                      final updated = EmployeeModel(
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
                      context.read<EmployeeBloc>().add(UpdateEmployeeEvent(updated));
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ─── Team Activity Log Card ────────────────────────────────────────────────

  Widget _buildTeamActivityCard() {
    // TODO: Real-time Dispatch Log - NOT wired to real data in this pass.
    // This requires creating an activity_log collection and adding triggers/write-hooks
    // across multiple operational modules (Installations, Payments, etc.) which is out of scope.
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Real-time Team Dispatch Log',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 56,
                    color: AppColors.mediumGray.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No recent activity',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Activity log will activate in a future release once background logging hooks are enabled.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.mediumGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
