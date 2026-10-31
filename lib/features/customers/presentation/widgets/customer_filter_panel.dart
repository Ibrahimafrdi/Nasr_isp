import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/customers/presentation/bloc/customers_bloc.dart';

const Color _kInk = Color(0xFF14213D);
const Color _kBorder = Color(0xFFE3E6EB);
const Color _kTeal = Color(0xFF0F766E);
const Color _kMuted = Color(0xFF5B6472);

/// One-row filter bar for the Customers list page.
///
/// Search comes first, then the status chips (with counts), then the
/// connection type. Pure UI - all state lives in [CustomersPage].
class CustomerFilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedStatus;
  final String? selectedConnectionType;
  final int activeFilterCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onConnectionTypeChanged;
  final VoidCallback? onClearFilters;

  /// Counts across all customers, not only the current page. Defaults to
  /// empty so older call sites keep compiling.
  final CustomersSummary summary;

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
    this.summary = CustomersSummary.empty,
  });

  int _countFor(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return summary.active;
      case CustomerStatus.expiringSoon:
        return summary.expiringSoon;
      case CustomerStatus.expired:
        return summary.expired;
      case CustomerStatus.inactive:
        return summary.inactive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(255, 86, 96, 115)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 400,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 14, color: _kInk),
              decoration: InputDecoration(
                hintText: 'Search name, phone, CNIC or address',
                hintStyle: const TextStyle(fontSize: 14, color: _kMuted),
                prefixIcon: const Icon(Icons.search, size: 20, color: _kMuted),
                filled: true,
                fillColor: Colors.white,
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
            ),
          ),
          _FilterChipButton(
            label: 'All ${summary.total}',
            selected: selectedStatus == null,
            onTap: () => onStatusChanged(null),
          ),
          ...CustomerStatus.values.map(
            (s) => _FilterChipButton(
              label: '${s.label} ${_countFor(s)}',
              selected: selectedStatus == s.label,
              onTap: () => onStatusChanged(s.label),
            ),
          ),
          Container(width: 1, height: 28, color: _kBorder),
          _FilterChipButton(
            label: 'Any type',
            selected: selectedConnectionType == null,
            onTap: () => onConnectionTypeChanged(null),
          ),
          _FilterChipButton(
            label: 'Wireless',
            selected: selectedConnectionType == 'wireless',
            onTap: () => onConnectionTypeChanged('wireless'),
          ),
          _FilterChipButton(
            label: 'Fiber',
            selected: selectedConnectionType == 'fiber',
            onTap: () => onConnectionTypeChanged('fiber'),
          ),
          if (activeFilterCount > 0 && onClearFilters != null)
            TextButton(
              onPressed: onClearFilters,
              style: TextButton.styleFrom(
                foregroundColor: _kTeal,
                minimumSize: const Size(0, 44),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Clear filters'),
            ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _kTeal : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? _kTeal : _kBorder),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? Colors.white : _kInk,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
