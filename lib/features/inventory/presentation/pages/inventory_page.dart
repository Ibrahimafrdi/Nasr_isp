import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Sample static data representing local inventory
  final List<Map<String, dynamic>> _inventoryItems = [
    {
      'id': '1',
      'name': 'Fiber Home GPON ONU',
      'category': 'ONU Devices',
      'total': 150,
      'available': 45,
      'used': 105,
      'minThreshold': 20,
    },
    {
      'id': '2',
      'name': 'Tenda F3 Wireless Router',
      'category': 'Routers',
      'total': 80,
      'available': 8,
      'used': 72,
      'minThreshold': 15,
    },
    {
      'id': '3',
      'name': 'TP-Link 8-Port PoE Switch',
      'category': 'Switches',
      'total': 25,
      'available': 12,
      'used': 13,
      'minThreshold': 5,
    },
    {
      'id': '4',
      'name': 'Cat6 Fiber Patch Cord 3m',
      'category': 'Cables',
      'total': 500,
      'available': 180,
      'used': 320,
      'minThreshold': 50,
    },
    {
      'id': '5',
      'name': 'SC/UPC Fiber Connectors',
      'category': 'Connectors',
      'total': 1000,
      'available': 0,
      'used': 1000,
      'minThreshold': 100,
    },
  ];

  final List<Map<String, dynamic>> _historyLogs = [
    {
      'date': 'May 20, 2026',
      'name': 'Tenda F3 Wireless Router',
      'qty': '+50',
      'action': 'Restock',
      'operator': 'Muhammad Zain'
    },
    {
      'date': 'May 18, 2026',
      'name': 'SC/UPC Fiber Connectors',
      'qty': '-120',
      'action': 'Dispatched',
      'operator': 'Ahmad Ali (Tech)'
    },
    {
      'date': 'May 15, 2026',
      'name': 'Fiber Home GPON ONU',
      'qty': '+30',
      'action': 'Restock',
      'operator': 'Muhammad Zain'
    },
  ];

  void _showAddStockDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    String category = 'ONU Devices';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.whiteColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text('Add New Equipment Stock', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppFormField(
                        label: 'Equipment / Device Name',
                        controller: nameController,
                        hintText: 'e.g. Huawei GPON ONU',
                        isRequired: true,
                        validator: (v) => v == null || v.isEmpty ? 'Device name required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(labelText: 'Equipment Category'),
                        items: ['ONU Devices', 'Routers', 'Switches', 'Cables', 'Connectors', 'Other']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => category = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      AppFormField(
                        label: 'Quantity Added',
                        controller: qtyController,
                        hintText: 'e.g. 50',
                        keyboardType: TextInputType.number,
                        isRequired: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Quantity required';
                          if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Enter valid positive count';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.mediumGray)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        final addedQty = int.parse(qtyController.text);
                        // Search if item already exists
                        final existingIndex = _inventoryItems.indexWhere(
                          (item) => item['name'].toString().toLowerCase() == nameController.text.trim().toLowerCase()
                        );
                        if (existingIndex != -1) {
                          _inventoryItems[existingIndex]['total'] = _inventoryItems[existingIndex]['total'] + addedQty;
                          _inventoryItems[existingIndex]['available'] = _inventoryItems[existingIndex]['available'] + addedQty;
                        } else {
                          _inventoryItems.add({
                            'id': DateTime.now().millisecondsSinceEpoch.toString(),
                            'name': nameController.text.trim(),
                            'category': category,
                            'total': addedQty,
                            'available': addedQty,
                            'used': 0,
                            'minThreshold': 10,
                          });
                        }

                        // Add to history
                        _historyLogs.insert(0, {
                          'date': 'Today',
                          'name': nameController.text.trim(),
                          'qty': '+$addedQty',
                          'action': 'Restock',
                          'operator': 'Muhammad Zain',
                        });
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stock logged successfully!'), backgroundColor: AppTheme.successColor),
                      );
                    }
                  },
                  child: const Text('Save Stock'),
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: Text('Not authenticated'));
        }

        final filteredItems = _inventoryItems.where((item) {
          final matchesSearch = item['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCategory = _selectedCategory == 'All' || item['category'] == _selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        // Calculations for header counters
        final int totalDevices = _inventoryItems
            .where((i) => i['category'] == 'ONU Devices' || i['category'] == 'Routers')
            .fold(0, (sum, i) => sum + (i['available'] as int));

        final int lowStockCount = _inventoryItems.where((i) => (i['available'] as int) <= (i['minThreshold'] as int)).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb
              Breadcrumb(
                items: [
                  BreadcrumbItem(label: 'Home', onTap: () => context.go(RoutePaths.dashboard)),
                  BreadcrumbItem(label: 'Inventory'),
                ],
              ),
              const SizedBox(height: 16),

              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hardware & Device Inventory',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track equipment distribution, ONU routers stock, and technician issues.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddStockDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Stock'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // KPI Stock metrics summary cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  return GridView.count(
                    crossAxisCount: isDesktop ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isDesktop ? 1.8 : 1.3,
                    children: [
                      _buildMetricCard(
                        'Total Devices Available',
                        '$totalDevices',
                        'ONUs & Routers',
                        Icons.router,
                        AppTheme.primaryColor,
                      ),
                      _buildMetricCard(
                        'Low Stock Alerts',
                        '$lowStockCount Items',
                        'Below minimum warning limit',
                        Icons.warning_amber_rounded,
                        lowStockCount > 0 ? AppTheme.errorColor : AppTheme.successColor,
                      ),
                      _buildMetricCard(
                        'Active Switches',
                        '${_inventoryItems.firstWhere((i) => i['category'] == 'Switches')['available']}',
                        'Ready in office storage',
                        Icons.settings_input_component,
                        Colors.purple,
                      ),
                      _buildMetricCard(
                        'Cables Stock (Meters)',
                        '${_inventoryItems.firstWhere((i) => i['category'] == 'Cables')['available']}m',
                        'Available for field installation',
                        Icons.cable,
                        Colors.teal,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Filter chips and search bar
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search equipment by name...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                fillColor: AppTheme.veryLightGray,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (val) {
                                setState(() => _searchQuery = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'ONU Devices', 'Routers', 'Switches', 'Cables', 'Connectors']
                              .map((cat) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(cat),
                                      selected: _selectedCategory == cat,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => _selectedCategory = cat);
                                        }
                                      },
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Main Inventory List Card
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Office Stock Inventory Directory',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const Divider(),
                    DataTableWrapper(
                      columns: const [
                        DataColumn(label: Text('Equipment Name')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Total Ledger')),
                        DataColumn(label: Text('Available Stock')),
                        DataColumn(label: Text('Used/Issued')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: filteredItems.map((item) {
                        final avail = item['available'] as int;
                        final min = item['minThreshold'] as int;
                        final total = item['total'] as int;
                        final used = item['used'] as int;

                        String statusText = 'Available';
                        Color statusColor = AppTheme.successColor;
                        if (avail == 0) {
                          statusText = 'Out of Stock';
                          statusColor = AppTheme.errorColor;
                        } else if (avail <= min) {
                          statusText = 'Low Stock';
                          statusColor = AppTheme.warningColor;
                        }

                        return DataRow(cells: [
                          DataCell(Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(item['category'] as String)),
                          DataCell(Text('$total')),
                          DataCell(Text('$avail', style: TextStyle(fontWeight: FontWeight.bold, color: statusColor))),
                          DataCell(Text('$used')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                    if (filteredItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No matching items found.')),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Restock & Logs timeline
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Stock Activities',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 24),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _historyLogs.length,
                        itemBuilder: (context, index) {
                          final log = _historyLogs[index];
                          final isAdd = log['qty'].toString().contains('+');
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: isAdd ? AppTheme.successColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1),
                              child: Icon(
                                isAdd ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isAdd ? AppTheme.successColor : AppTheme.errorColor,
                                size: 16,
                              ),
                            ),
                            title: Text(log['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Logged by ${log['operator']} on ${log['date']}'),
                            trailing: Text(
                              log['qty'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isAdd ? AppTheme.successColor : AppTheme.errorColor,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      )
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

  Widget _buildMetricCard(String label, String value, String subtitle, IconData icon, Color iconColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.mediumGray)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.mediumGray), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
