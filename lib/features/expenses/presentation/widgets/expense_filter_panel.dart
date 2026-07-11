import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/expenses/domain/entities/expense_entity.dart';
import 'package:nasr_isp/shared/widgets/app_filter_widgets.dart';

/// Filter panel for the Expenses list page.
///
/// Pure UI — all state lives in [ExpensesPage]; callbacks are received.
class ExpenseFilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String? categoryFilter;
  final bool hasDateRange;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;
  final int activeFilterCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onPickDateRange;
  final VoidCallback? onClearDateRange;
  final ValueChanged<String?> onCategoryFilterChanged;
  final VoidCallback onClearFilters;

  const ExpenseFilterPanel({
    super.key,
    required this.searchController,
    required this.categoryFilter,
    required this.hasDateRange,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.activeFilterCount,
    required this.onSearchChanged,
    required this.onPickDateRange,
    this.onClearDateRange,
    required this.onCategoryFilterChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final categoryLabels = ExpenseCategory.values.map((c) => c.label).toList();

    return AppFilterContainer(
      title: 'Search & Filter Expenses',
      titleIcon: Icons.receipt_long,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSearchField(
            controller: searchController,
            hintText: 'Search by title, paid by, or notes...',
            onChanged: onSearchChanged,
            onClear: () {
              searchController.clear();
              onSearchChanged('');
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onPickDateRange,
                icon: const Icon(Icons.date_range_rounded, size: 16),
                label: Text(
                  hasDateRange
                      ? '${DateTimeUtils.formatDate(dateRangeStart!)}  →  ${DateTimeUtils.formatDate(dateRangeEnd!)}'
                      : 'Select Date Range',
                  style: const TextStyle(fontSize: 12.5),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
              if (hasDateRange)
                IconButton(
                  tooltip: 'Clear date range',
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: onClearDateRange,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppStatusChipGroup(
                options: categoryLabels,
                selected: categoryFilter,
                allLabel: 'All Categories',
                onChanged: onCategoryFilterChanged,
              ),
              AppFilterBadge(count: activeFilterCount),
              AppClearFilterButton(
                isVisible: activeFilterCount > 0,
                onClear: onClearFilters,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
