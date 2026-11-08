import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';

const _accent = Color(0xFF0F766E);
const _ink = Color(0xFF14213D);
const _line = Color(0xFFC9CED6);

/// Filter bar for the Installations list page.
///
/// Pure UI: all state lives in [InstallationsPage]; callbacks are received.
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

  OutlineInputBorder get _border => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: _line),
  );

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search customer by name, user ID or installer...',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: _border,
        enabledBorder: _border,
      ),
    );

    final linePills = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Pill(
          label: 'All lines',
          selected: selectedConnectionType == null,
          onTap: () => onConnectionTypeChanged(null),
        ),
        for (final t in ConnectionType.values)
          _Pill(
            label: t.displayName,
            selected: selectedConnectionType == t.name,
            onTap: () => onConnectionTypeChanged(t.name),
          ),
      ],
    );

    final technician = DropdownButtonFormField<String?>(
      value: selectedEmployeeId,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _border,
        enabledBorder: _border,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('All technicians')),
        ...employeesList.map(
          (e) => DropdownMenuItem(
            value: e['id'] as String,
            child: Text(e['name'] as String, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onEmployeeChanged,
    );

    final statusPills = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Pill(
          label: 'All',
          selected: selectedStatus == null,
          onTap: () => onStatusChanged(null),
        ),
        for (final s in InstallationStatus.values)
          _Pill(
            label: s.displayName,
            selected: selectedStatus == s.name,
            onTap: () => onStatusChanged(s.name),
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
            if (c.maxWidth >= 1000) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: 280, child: search),
                  const SizedBox(width: 16),
                  Expanded(child: linePills),
                  const SizedBox(width: 16),
                  SizedBox(width: 220, child: technician),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                search,
                const SizedBox(height: 12),
                linePills,
                const SizedBox(height: 12),
                technician,
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        statusPills,
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
