import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/shared/widgets/app_filter_widgets.dart';
import 'package:nasr_isp/shared/widgets/reusable_filter_components.dart';

/// Filter panel for the Installations list page.
///
/// Pure UI — all state lives in [InstallationsPage]; callbacks are received.
class InstallationFilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedStatus;
  final String? selectedConnectionType;
  final String? selectedEmployeeId;
  final List<Map<String, dynamic>> employeesList;
  final int activeFilterCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onConnectionTypeChanged;
  final ValueChanged<String?> onEmployeeChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClearFilters;

  const InstallationFilterPanel({
    super.key,
    required this.searchController,
    required this.selectedStatus,
    required this.selectedConnectionType,
    required this.selectedEmployeeId,
    required this.employeesList,
    required this.activeFilterCount,
    required this.onSearchChanged,
    required this.onConnectionTypeChanged,
    required this.onEmployeeChanged,
    required this.onStatusChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return AppFilterContainer(
      title: 'Search & Filter Installations',
      titleIcon: Icons.construction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterPanelHeader(
            searchController: searchController,
            onSearchChanged: onSearchChanged,
            onClearFilters: activeFilterCount > 0 ? onClearFilters : null,
            activeFilterCount: activeFilterCount,
            title: 'Filters',
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              // Connection Type Dropdown Filter
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: selectedConnectionType,
                  decoration: const InputDecoration(labelText: 'Connection Line'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Connections')),
                    ...ConnectionType.values.map((t) => DropdownMenuItem(
                          value: t.name,
                          child: Text(t.displayName),
                        ))
                  ],
                  onChanged: onConnectionTypeChanged,
                ),
              ),
              const SizedBox(width: 16),
              // Assigned Employee Dropdown Filter
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: selectedEmployeeId,
                  decoration: const InputDecoration(labelText: 'Technician Filter'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Technicians')),
                    ...employeesList.map((e) => DropdownMenuItem(
                          value: e['id'] as String,
                          child: Text(e['name'] as String),
                        ))
                  ],
                  onChanged: onEmployeeChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Installation Status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppStatusChipGroup(
            options: InstallationStatus.values.map((s) => s.displayName).toList(),
            selected: selectedStatus != null
                ? InstallationStatus.values
                    .firstWhere((s) => s.name == selectedStatus)
                    .displayName
                : null,
            onChanged: (label) {
              final status = label == null
                  ? null
                  : InstallationStatus.values
                      .firstWhere((s) => s.displayName == label)
                      .name;
              onStatusChanged(status);
            },
          ),
        ],
      ),
    );
  }
}
