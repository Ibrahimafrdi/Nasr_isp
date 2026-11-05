import 'package:flutter/material.dart';

const Color _kInk = Color(0xFF14213D);
const Color _kBorder = Color(0xFFE3E6EB);
const Color _kTeal = Color(0xFF0F766E);
const Color _kMuted = Color(0xFF5B6472);
const Color _kSoft = Color(0xFFF1F3F6);

/// One slim row: search on the left, connection type on the right.
///
/// Status filtering lives in `CustomerSummaryTiles` above the list, so this
/// bar only needs the two controls left. Pure UI - state lives in the page.
class CustomerFilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedConnectionType; // null = all, 'wireless', 'fiber'
  final int activeFilterCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onConnectionTypeChanged;
  final VoidCallback? onClearFilters;

  const CustomerFilterPanel({
    super.key,
    required this.searchController,
    required this.selectedConnectionType,
    required this.activeFilterCount,
    required this.onSearchChanged,
    required this.onConnectionTypeChanged,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      style: const TextStyle(fontSize: 14, color: _kInk),
      decoration: InputDecoration(
        hintText: 'Search name, phone, CNIC or address',
        hintStyle: const TextStyle(fontSize: 14, color: _kMuted),
        prefixIcon: const Icon(Icons.search, size: 20, color: _kMuted),
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close, size: 18, color: _kMuted),
                onPressed: () {
                  searchController.clear();
                  onSearchChanged('');
                },
              ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kTeal, width: 1.5),
        ),
      ),
    );

    final type = _TypeSegment(
      selected: selectedConnectionType,
      onChanged: onConnectionTypeChanged,
    );

    final clear = (activeFilterCount > 0 && onClearFilters != null)
        ? TextButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: const Text('Clear filters'),
            style: TextButton.styleFrom(
              foregroundColor: _kTeal,
              minimumSize: const Size(0, 44),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Wide: one row. Narrow: search on top, controls below.
        if (constraints.maxWidth >= 720) {
          return Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: search,
                  ),
                ),
              ),
              if (clear != null) ...[clear, const SizedBox(width: 8)],
              type,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            search,
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [type, if (clear != null) clear],
            ),
          ],
        );
      },
    );
  }
}

/// "All types | Wireless | Fiber" as one segmented control.
class _TypeSegment extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _TypeSegment({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, String? value, IconData? icon) {
      final isOn = selected == value;
      return Material(
        color: isOn ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        elevation: isOn ? 0.5 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(value),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isOn ? Border.all(color: _kBorder) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: isOn ? _kTeal : _kMuted),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isOn ? FontWeight.w600 : FontWeight.w500,
                    color: isOn ? _kTeal : _kInk,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kSoft,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('All types', null, null),
          const SizedBox(width: 2),
          seg('Wireless', 'wireless', Icons.wifi),
          const SizedBox(width: 2),
          seg('Fiber', 'fiber', Icons.cable),
        ],
      ),
    );
  }
}
