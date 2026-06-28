import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/shared/widgets/app_filter_widgets.dart';

/// Generic date range picker widget for filters
class DateRangePickerField extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final String label;

  const DateRangePickerField({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateRangeChanged,
    this.label = 'Date Range',
  });

  @override
  State<DateRangePickerField> createState() => _DateRangePickerFieldState();
}

class _DateRangePickerFieldState extends State<DateRangePickerField> {
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _updateDateDisplay();
  }

  void _updateDateDisplay() {
    if (widget.startDate != null && widget.endDate != null) {
      _dateController = TextEditingController(
        text:
            '${DateFormat('MMM dd').format(widget.startDate!)} - ${DateFormat('MMM dd, yyyy').format(widget.endDate!)}',
      );
    } else {
      _dateController = TextEditingController(text: '');
    }
  }

  @override
  void didUpdateWidget(DateRangePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _updateDateDisplay();
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: widget.startDate != null && widget.endDate != null
          ? DateTimeRange(start: widget.startDate!, end: widget.endDate!)
          : null,
    );

    if (picked != null) {
      widget.onDateRangeChanged(picked);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDateRange(context),
      child: TextField(
        controller: _dateController,
        enabled: false,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: 'Select date range',
          prefixIcon: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
          suffixIcon: widget.startDate != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => widget.onDateRangeChanged(null),
                )
              : null,
          filled: true,
          fillColor: AppColors.offWhite,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: BorderSide(color: AppColors.lightGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.8)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.6)),
          ),
        ),
      ),
    );
  }
}

/// Generic multi-select status filter widget
class StatusFilterChips extends StatelessWidget {
  final List<String> availableStatuses;
  final List<String> selectedStatuses;
  final ValueChanged<List<String>> onStatusesChanged;
  final Map<String, IconData>? statusIcons;

  const StatusFilterChips({
    super.key,
    required this.availableStatuses,
    required this.selectedStatuses,
    required this.onStatusesChanged,
    this.statusIcons,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: availableStatuses.map((status) {
        final isSelected = selectedStatuses.contains(status);
        return AppFilterChip(
          label: status,
          selected: isSelected,
          icon: statusIcons?[status],
          onSelected: (_) {
            final updatedStatuses = List<String>.from(selectedStatuses);
            if (isSelected) {
              updatedStatuses.remove(status);
            } else {
              updatedStatuses.add(status);
            }
            onStatusesChanged(updatedStatuses);
          },
        );
      }).toList(),
    );
  }
}

/// Generic category filter widget
class CategoryFilterDropdown extends StatelessWidget {
  final List<String> categories;
  final List<String> selectedCategories;
  final ValueChanged<List<String>> onCategoriesChanged;
  final String label;

  const CategoryFilterDropdown({
    super.key,
    required this.categories,
    required this.selectedCategories,
    required this.onCategoriesChanged,
    this.label = 'Categories',
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.offWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: AppColors.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.8)),
        ),
      ),
      items: categories
          .map(
            (category) =>
                DropdownMenuItem(value: category, child: Text(category)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          final updated = List<String>.from(selectedCategories);
          if (updated.contains(value)) {
            updated.remove(value);
          } else {
            updated.add(value);
          }
          onCategoriesChanged(updated);
        }
      },
    );
  }
}

/// Reusable filter panel header with search and action buttons
class FilterPanelHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onClearFilters;
  final int activeFilterCount;
  final String title;

  const FilterPanelHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    this.onClearFilters,
    this.activeFilterCount = 0,
    this.title = 'Filters',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            Row(
              children: [
                AppFilterBadge(count: activeFilterCount),
                if (activeFilterCount > 0) ...[
                  const SizedBox(width: AppSpacing.md),
                  AppClearFilterButton(
                    isVisible: activeFilterCount > 0,
                    onClear: onClearFilters ?? () {},
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSearchField(
          controller: searchController,
          hintText: 'Search...',
          onChanged: onSearchChanged,
        ),
      ],
    );
  }
}
