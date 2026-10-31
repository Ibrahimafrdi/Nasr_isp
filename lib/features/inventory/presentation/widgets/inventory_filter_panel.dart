import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';

const _accent = Color(0xFF0F766E);
const _ink = Color(0xFF14213D);
const _line = Color(0xFFC9CED6);

/// One-row filter bar for the Inventory page.
///
/// Pure UI: all state lives in the page; callbacks are received.
class InventoryFilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final InventoryCategory? selectedCategory;
  final InventoryConnectionType? selectedConnectionType;
  final bool lowStockOnly;
  final int activeFilterCount;
  final String Function(InventoryCategory category) categoryLabel;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<InventoryCategory?> onCategoryChanged;
  final ValueChanged<InventoryConnectionType?> onConnectionTypeChanged;
  final ValueChanged<bool> onLowStockOnlyChanged;
  final VoidCallback onClearFilters;

  const InventoryFilterPanel({
    super.key,
    required this.searchController,
    required this.selectedCategory,
    required this.selectedConnectionType,
    required this.lowStockOnly,
    required this.activeFilterCount,
    required this.categoryLabel,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onConnectionTypeChanged,
    required this.onLowStockOnlyChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search by name',
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

    final pills = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Pill(
          label: 'All',
          selected: selectedCategory == null,
          onTap: () => onCategoryChanged(null),
        ),
        for (final c in InventoryCategory.values)
          _Pill(
            label: categoryLabel(c),
            selected: selectedCategory == c,
            onTap: () => onCategoryChanged(c),
          ),
        const SizedBox(width: 12),
        _Pill(
          label: 'All types',
          selected: selectedConnectionType == null,
          onTap: () => onConnectionTypeChanged(null),
        ),
        for (final t in InventoryConnectionType.values.where(
          (c) => c != InventoryConnectionType.both,
        ))
          _Pill(
            label: t.label,
            selected: selectedConnectionType == t,
            onTap: () => onConnectionTypeChanged(t),
          ),
        const SizedBox(width: 12),
        _Pill(
          label: 'Low stock only',
          selected: lowStockOnly,
          onTap: () => onLowStockOnlyChanged(!lowStockOnly),
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

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 1000) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 280, child: search),
              const SizedBox(width: 16),
              Expanded(child: pills),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [search, const SizedBox(height: 12), pills],
        );
      },
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
