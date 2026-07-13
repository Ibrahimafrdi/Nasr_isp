import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/shared/widgets/app_filter_widgets.dart';
import 'package:nasr_isp/shared/widgets/reusable_filter_components.dart';

/// Filter panel for the Inventory page.
///
/// Pure UI — all state lives in [_InventoryViewState]; callbacks are received.
class InventoryFilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final InventoryCategory? selectedCategory;
  final InventoryConnectionType? selectedConnectionType;
  final int activeFilterCount;
  final String Function(InventoryCategory category) categoryLabel;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<InventoryCategory?> onCategoryChanged;
  final ValueChanged<InventoryConnectionType?> onConnectionTypeChanged;
  final VoidCallback onClearFilters;

  const InventoryFilterPanel({
    super.key,
    required this.searchController,
    required this.selectedCategory,
    required this.selectedConnectionType,
    required this.activeFilterCount,
    required this.categoryLabel,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onConnectionTypeChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return AppFilterContainer(
      title: 'Search & Filter Inventory',
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
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          AppStatusChipGroup(
            options: InventoryCategory.values.map(categoryLabel).toList(),
            selected: selectedCategory != null
                ? categoryLabel(selectedCategory!)
                : null,
            onChanged: (label) {
              final cat = label == null
                  ? null
                  : InventoryCategory.values.firstWhere(
                      (c) => categoryLabel(c) == label,
                    );
              onCategoryChanged(cat);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Used For',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          AppStatusChipGroup(
            options: InventoryConnectionType.values.map((c) => c.label).toList(),
            selected: selectedConnectionType?.label,
            onChanged: (label) {
              final type = label == null
                  ? null
                  : InventoryConnectionType.values.firstWhere(
                      (c) => c.label == label,
                    );
              onConnectionTypeChanged(type);
            },
          ),
        ],
      ),
    );
  }
}
