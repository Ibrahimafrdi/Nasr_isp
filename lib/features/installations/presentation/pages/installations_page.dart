import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class InstallationsPage extends StatefulWidget {
  const InstallationsPage({Key? key}) : super(key: key);

  @override
  State<InstallationsPage> createState() => _InstallationsPageState();
}

class _InstallationsPageState extends State<InstallationsPage> {
  final List<Map<String, dynamic>> _installations = [
    {
      'id': 'inst_1',
      'customer': 'Customer 2',
      'technician': 'Technician Hamza',
      'date': '2026-05-18',
      'materials': 'XPON ONT Router, 180m Drop Wire, 2x RJ45, Patch cord',
      'cost': 4500.0,
      'fee': 6000.0,
      'status': 'Completed',
    },
    {
      'id': 'inst_2',
      'customer': 'Customer 14',
      'technician': 'Technician Bilal',
      'date': '2026-05-17',
      'materials': 'XPON ONT Router, 240m Drop Wire, Fast connectors, Patch cord',
      'cost': 5300.0,
      'fee': 7000.0,
      'status': 'Completed',
    },
    {
      'id': 'inst_3',
      'customer': 'Customer 8',
      'technician': 'Technician Ali',
      'date': '2026-05-16',
      'materials': 'ONT Router, 90m Drop Wire, Patch cord',
      'cost': 3800.0,
      'fee': 5000.0,
      'status': 'Completed',
    },
    {
      'id': 'inst_4',
      'customer': 'Customer 31',
      'technician': 'Technician Sana',
      'date': '2026-05-19',
      'materials': 'Dual-Band XPON Router, 300m Drop Wire, Fast connectors',
      'cost': 6200.0,
      'fee': 8500.0,
      'status': 'Scheduled',
    },
  ];

  void _showAddInstallationDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final customerController = TextEditingController();
    final materialsController = TextEditingController();
    final costController = TextEditingController();
    final feeController = TextEditingController();
    String selectedTechnician = 'Technician Hamza';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Provision New Physical Line Installation'),
              content: Form(
                key: formKey,
                child: Container(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: customerController,
                        decoration: const InputDecoration(labelText: 'Customer Account / Name'),
                        validator: (v) => v == null || v.isEmpty ? 'Customer name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedTechnician,
                        decoration: const InputDecoration(labelText: 'Assigned Installer / Technician'),
                        items: const [
                          DropdownMenuItem(value: 'Technician Ali', child: Text('Technician Ali')),
                          DropdownMenuItem(value: 'Technician Hamza', child: Text('Technician Hamza')),
                          DropdownMenuItem(value: 'Technician Sana', child: Text('Technician Sana')),
                          DropdownMenuItem(value: 'Technician Bilal', child: Text('Technician Bilal')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => selectedTechnician = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: materialsController,
                        decoration: const InputDecoration(
                          labelText: 'Bill of Materials (BOM)',
                          hintText: 'e.g. ONT Router, 150m cable, patch cord',
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Materials list is required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: costController,
                              decoration: const InputDecoration(labelText: 'Internal Material Cost (PKR)'),
                              keyboardType: TextInputType.number,
                              validator: (v) => v == null || v.isEmpty ? 'Cost is required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: feeController,
                              decoration: const InputDecoration(labelText: 'Installation Fee Charged (PKR)'),
                              keyboardType: TextInputType.number,
                              validator: (v) => v == null || v.isEmpty ? 'Fee is required' : null,
                            ),
                          ),
                        ],
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
                            await Future.delayed(const Duration(milliseconds: 800));
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Physical connection provisioned successfully!'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                            this.setState(() {
                              _installations.insert(0, {
                                'id': 'inst_${_installations.length + 1}',
                                'customer': customerController.text,
                                'technician': selectedTechnician,
                                'date': DateTime.now().toString().split(' ')[0],
                                'materials': materialsController.text,
                                'cost': double.parse(costController.text),
                                'fee': double.parse(feeController.text),
                                'status': 'Completed',
                              });
                            });
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: Text(isSaving ? 'Logging...' : 'Confirm Provision'),
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
    double totalCost = _installations.fold(0.0, (s, i) => s + (i['cost'] as double));
    double totalFee = _installations.fold(0.0, (s, i) => s + (i['fee'] as double));
    double netMargin = totalFee - totalCost;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: Text('Not authenticated'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Breadcrumb(
                    items: [
                      BreadcrumbItem(label: 'Home', onTap: () => context.go(RoutePaths.dashboard)),
                      BreadcrumbItem(label: 'Installations'),
                    ],
                  ),
                  if (authState.user.role.isAdmin)
                    ElevatedButton.icon(
                      onPressed: () => _showAddInstallationDialog(context),
                      icon: const Icon(Icons.construction, size: 18),
                      label: const Text('Log Installation'),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Metric Summary Cards
              Row(
                children: [
                  Expanded(
                    child: DashboardCard(
                      label: 'Gross Installation Fees',
                      value: DateTimeUtils.formatCurrency(totalFee),
                      icon: Icons.payments,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardCard(
                      label: 'Total Material & Cable Costs',
                      value: DateTimeUtils.formatCurrency(totalCost),
                      icon: Icons.shopping_bag_outlined,
                      backgroundColor: AppTheme.errorColor.withOpacity(0.04),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardCard(
                      label: 'Net Installation Profit',
                      value: DateTimeUtils.formatCurrency(netMargin),
                      icon: Icons.account_balance_wallet,
                      backgroundColor: AppTheme.successColor.withOpacity(0.05),
                      subtitle: '${((netMargin / totalFee) * 100).toStringAsFixed(1)}% profit margin',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Installations table
              Card(
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
                        'Installation Operations Log',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildInstallationsTable(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstallationsTable() {
    return DataTableWrapper(
      columns: const [
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Assigned Installer')),
        DataColumn(label: Text('Date Installed')),
        DataColumn(label: Text('Materials Used (BOM)')),
        DataColumn(label: Text('Material Cost')),
        DataColumn(label: Text('Setup Fee Charged')),
        DataColumn(label: Text('Net Return')),
        DataColumn(label: Text('Status')),
      ],
      rows: _installations.map((inst) {
        double cost = inst['cost'] as double;
        double fee = inst['fee'] as double;
        double profit = fee - cost;
        final bool isScheduled = inst['status'] == 'Scheduled';

        return DataRow(
          cells: [
            DataCell(Text(inst['customer'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor))),
            DataCell(Text(inst['technician'] as String)),
            DataCell(Text(DateTimeUtils.formatDate(DateTime.parse(inst['date'] as String)))),
            DataCell(
              Tooltip(
                message: inst['materials'] as String,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(inst['materials'] as String, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ),
            DataCell(Text(DateTimeUtils.formatCurrency(cost))),
            DataCell(Text(DateTimeUtils.formatCurrency(fee))),
            DataCell(
              Text(
                DateTimeUtils.formatCurrency(profit),
                style: TextStyle(
                  color: profit > 0 ? AppTheme.successColor : AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isScheduled ? AppTheme.warningColor.withOpacity(0.1) : AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  inst['status'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isScheduled ? AppTheme.warningColor : AppTheme.successColor,
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
