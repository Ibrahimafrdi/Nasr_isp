import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/shared/widgets/app_filter_widgets.dart';
import 'package:nasr_isp/shared/widgets/reusable_filter_components.dart';

/// Filter panel for the Customers list page.
///
/// Pure UI — all state lives in [CustomersPage]; this widget receives
/// controllers, current selections, and callbacks.
class CustomerFilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedStatus;
  final String? selectedConnectionType;
  final int activeFilterCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onConnectionTypeChanged;
  final VoidCallback? onClearFilters;

  const CustomerFilterPanel({
    super.key,
    required this.searchController,
    required this.selectedStatus,
    required this.selectedConnectionType,
    required this.activeFilterCount,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onConnectionTypeChanged,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return AppFilterContainer(
      title: 'Search & Filter Customers',
      titleIcon: Icons.filter_list,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterPanelHeader(
            searchController: searchController,
            onSearchChanged: onSearchChanged,
            onClearFilters: activeFilterCount > 0 ? onClearFilters : null,
            activeFilterCount: activeFilterCount,
            title: 'Active Filters',
          ),
          SizedBox(height: AppSpacing.lg),

          // Status filter chips
          const Text(
            'Subscription Status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          AppStatusChipGroup(
            options: CustomerStatus.values.map((s) => s.label).toList(),
            selected: selectedStatus,
            onChanged: onStatusChanged,
          ),
          const SizedBox(height: 16),

          // Connection type chips
          const Text(
            'Connection Type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ConnectionChip(
                label: 'All',
                value: null,
                selectedValue: selectedConnectionType,
                onChanged: onConnectionTypeChanged,
              ),
              const SizedBox(width: 8),
              _ConnectionChip(
                label: 'Wireless',
                value: 'wireless',
                selectedValue: selectedConnectionType,
                onChanged: onConnectionTypeChanged,
              ),
              const SizedBox(width: 8),
              _ConnectionChip(
                label: 'Fiber',
                value: 'fiber',
                selectedValue: selectedConnectionType,
                onChanged: onConnectionTypeChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  final String label;
  final String? value;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  const _ConnectionChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;
    final color = value == 'fiber' ? Colors.purple : AppColors.primaryBlue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: value == null
          ? AppColors.primaryBlue.withOpacity(0.15)
          : color.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected
            ? (value == null ? AppColors.primaryBlue : color)
            : AppColors.charcoal,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? (value == null ? AppColors.primaryBlue : color)
              : Colors.grey.shade300,
        ),
      ),
      onSelected: (_) => onChanged(value),
    );
  }
}
