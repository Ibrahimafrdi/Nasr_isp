import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({Key? key}) : super(key: key);

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final List<Map<String, dynamic>> _employees = [
    {
      'id': 'emp_1',
      'name': 'Technician Ali',
      'role': 'Senior Line Technician',
      'phone': '+923001112221',
      'area': 'DHA & Clifton',
      'subscribers': 42,
      'collections': 38,
      'efficiency': 90.5,
    },
    {
      'id': 'emp_2',
      'name': 'Technician Hamza',
      'role': 'Fiber Optic Specialist',
      'phone': '+923001112222',
      'area': 'Gulshan & Johar',
      'subscribers': 36,
      'collections': 35,
      'efficiency': 97.2,
    },
    {
      'id': 'emp_3',
      'name': 'Technician Sana',
      'role': 'Customer Support Tech',
      'phone': '+923001112223',
      'area': 'Nazimabad & F.B Area',
      'subscribers': 28,
      'collections': 24,
      'efficiency': 85.7,
    },
    {
      'id': 'emp_4',
      'name': 'Technician Bilal',
      'role': 'Network Operations Assistant',
      'phone': '+923001112224',
      'area': 'Saddar & Tariq Road',
      'subscribers': 44,
      'collections': 41,
      'efficiency': 93.1,
    },
  ];

  void _showAddEmployeeDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final roleController = TextEditingController(text: 'Fiber Technician');
    String selectedArea = 'DHA & Clifton';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Team Member / Installer'),
              content: Form(
                key: formKey,
                child: Container(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Employee Full Name',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Number',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Phone is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: roleController,
                        decoration: const InputDecoration(
                          labelText: 'Job Role / Designation',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Role is required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedArea,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Operational Sector',
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
                    ],
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
                            setState(() => isSaving = true);
                            await Future.delayed(
                              const Duration(milliseconds: 800),
                            );
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Team member ${nameController.text} added successfully!',
                                ),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                            this.setState(() {
                              _employees.add({
                                'id': 'emp_${_employees.length + 1}',
                                'name': nameController.text,
                                'role': roleController.text,
                                'phone': phoneController.text,
                                'area': selectedArea,
                                'subscribers': 0,
                                'collections': 0,
                                'efficiency': 100.0,
                              });
                            });
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
                  label: Text(isSaving ? 'Saving...' : 'Add Employee'),
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
    int totalSubs = _employees.fold(0, (s, e) => s + (e['subscribers'] as int));
    int totalColl = _employees.fold(0, (s, e) => s + (e['collections'] as int));
    double avgEfficiency =
        _employees.fold(0.0, (s, e) => s + (e['efficiency'] as double)) /
        _employees.length;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Breadcrumb(
                    items: [
                      BreadcrumbItem(
                        label: 'Home',
                        onTap: () => context.go(RoutePaths.dashboard),
                      ),
                      BreadcrumbItem(label: 'Employees'),
                    ],
                  ),
                  if (authState.user.role.isAdmin)
                    ElevatedButton.icon(
                      onPressed: () => _showAddEmployeeDialog(context),
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text('Add Technician'),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Metric Summary Cards
              Row(
                children: [
                  Expanded(
                    child: DashboardCard(
                      label: 'Total Field Personnel',
                      value: _employees.length.toString(),
                      icon: Icons.groups_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardCard(
                      label: 'Subscribers Assigned',
                      value: totalSubs.toString(),
                      icon: Icons.supervised_user_circle_outlined,
                      subtitle:
                          '${(totalSubs / _employees.length).toStringAsFixed(0)} subs avg/technician',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardCard(
                      label: 'Average Billing Efficiency',
                      value: '${avgEfficiency.toStringAsFixed(1)}%',
                      icon: Icons.assignment_turned_in_outlined,
                      backgroundColor: AppTheme.successColor.withOpacity(0.05),
                      subtitle:
                          '$totalColl collections realized out of $totalSubs',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Layout: Table on left, Activity log on right
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  return isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildEmployeeTableCard()),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: _buildTeamActivityCard()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildEmployeeTableCard(),
                            const SizedBox(height: 24),
                            _buildTeamActivityCard(),
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

  Widget _buildEmployeeTableCard() {
    return Card(
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
              'Field Personnel Directory',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildEmployeesTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamActivityCard() {
    final activities = [
      {
        'tech': 'Technician Hamza',
        'event': 'Closed fiber connection setup for Customer 14',
        'time': '32 mins ago',
      },
      {
        'tech': 'Technician Ali',
        'event': 'Received monthly subscription cash PKR 1,500',
        'time': '1 hour ago',
      },
      {
        'tech': 'Technician Bilal',
        'event': 'Re-routed fiber ONT line in Sector DHA Block B',
        'time': '3 hours ago',
      },
      {
        'tech': 'Technician Sana',
        'event': 'Dispatched field support ticket for Customer 49',
        'time': '5 hours ago',
      },
      {
        'tech': 'Technician Hamza',
        'event': 'Marked installation completed at DHA Phase 2',
        'time': '1 day ago',
      },
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-time Team Dispatch Log',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final act = activities[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.engineering,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act['tech']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.darkGray,
                              ),
                            ),
                            Text(
                              act['event']!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.mediumGray,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              act['time']!,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeesTable() {
    return DataTableWrapper(
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Designation')),
        DataColumn(label: Text('Sector Area')),
        DataColumn(label: Text('Contact')),
        DataColumn(label: Text('Subscribers')),
        DataColumn(label: Text('Collections Target')),
        DataColumn(label: Text('Efficiency')),
      ],
      rows: _employees.map((emp) {
        double eff = emp['efficiency'] as double;
        return DataRow(
          cells: [
            DataCell(
              Text(
                emp['name'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            DataCell(Text(emp['role'] as String)),
            DataCell(Text(emp['area'] as String)),
            DataCell(Text(emp['phone'] as String)),
            DataCell(Text(emp['subscribers'].toString())),
            DataCell(Text('${emp['collections']}/${emp['subscribers']}')),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: eff > 90.0
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$eff%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: eff > 90.0
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
