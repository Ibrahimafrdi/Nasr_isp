import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/shared/widgets/app_filter_widgets.dart';
import 'package:nasr_isp/shared/widgets/reusable_filter_components.dart';

/// Filter panel for the Payments list page.
///
/// Pure UI — all state lives in [PaymentsPage]; callbacks are received.
class PaymentFilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedStatus;
  final int activeFilterCount;
  final bool hasDateRange;
  final String? dateRangeLabel;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onPickDateRange;
  final VoidCallback? onClearDateRange;
  final VoidCallback? onClearFilters;

  const PaymentFilterPanel({
    super.key,
    required this.searchController,
    required this.selectedStatus,
    required this.activeFilterCount,
    required this.hasDateRange,
    this.dateRangeLabel,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onPickDateRange,
    this.onClearDateRange,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return AppFilterContainer(
      title: 'Search & Filter Payments',
      titleIcon: Icons.receipt_long,
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
          SizedBox(height: AppSpacing.lg),

          // Status chips
          const Text(
            'Payment Status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          AppStatusChipGroup(
            options: const ['paid', 'unpaid', 'partial'],
            selected: selectedStatus,
            onChanged: onStatusChanged,
          ),
          const SizedBox(height: 14),

          // Date range selector
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onPickDateRange,
                icon: const Icon(Icons.date_range_rounded, size: 16),
                label: Text(
                  hasDateRange && dateRangeLabel != null
                      ? dateRangeLabel!
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
        ],
      ),
    );
  }
}
