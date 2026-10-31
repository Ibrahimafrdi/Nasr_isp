import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/utils/utils.dart';

const _accent = Color(0xFF0F766E);
const _ink = Color(0xFF14213D);
const _line = Color(0xFFC9CED6);

/// Filter bar for the Expenses list page.
///
/// Pure UI: all state lives in [ExpensesPage]; callbacks are received.
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
    final search = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search title, paid by or notes',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _line),
        ),
      ),
    );

    final dateButton = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: onPickDateRange,
          icon: const Icon(Icons.date_range_rounded, size: 18),
          label: Text(
            hasDateRange
                ? '${DateTimeUtils.formatDate(dateRangeStart!)}  →  ${DateTimeUtils.formatDate(dateRangeEnd!)}'
                : 'Pick dates',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: _ink,
            backgroundColor: Colors.white,
            side: BorderSide(color: hasDateRange ? _accent : _line),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        if (hasDateRange)
          IconButton(
            tooltip: 'Clear dates',
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onClearDateRange,
          ),
      ],
    );

    final pills = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Pill(
          label: 'All',
          selected: categoryFilter == null,
          onTap: () => onCategoryFilterChanged(null),
        ),
        for (final c in ExpenseCategory.values)
          _Pill(
            label: c.label,
            selected: categoryFilter == c.label,
            onTap: () => onCategoryFilterChanged(c.label),
          ),
        if (activeFilterCount > 0)
          TextButton(
            onPressed: onClearFilters,
            style: TextButton.styleFrom(
              foregroundColor: _accent,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('Clear filters'),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= 700) {
              return Row(
                children: [
                  SizedBox(width: 320, child: search),
                  const SizedBox(width: 16),
                  dateButton,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [search, const SizedBox(height: 12), dateButton],
            );
          },
        ),
        const SizedBox(height: 12),
        pills,
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _accent : Colors.white,
      shape: StadiumBorder(side: BorderSide(color: selected ? _accent : _line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : _ink,
            ),
          ),
        ),
      ),
    );
  }
}
