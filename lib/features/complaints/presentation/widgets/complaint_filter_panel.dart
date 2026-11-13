import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';

const _accent = Color(0xFF0F766E);
const _ink = Color(0xFF14213D);
const _line = Color(0xFFC9CED6);

/// Compact one-row filter toolbar for the Complaints page.
/// Desktop: search + Status + Priority + Type (+ Assignee for admins) + Clear.
/// Mobile: search on top, then dropdowns two per row.
class ComplaintFilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedStatus;
  final String? selectedPriority;
  final String? selectedType;
  final String? selectedEmployeeId;
  final bool mineOnly;
  final bool isAdmin;
  final List<Map<String, dynamic>> employeesList;
  final int activeFilterCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPriorityChanged;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onEmployeeChanged;
  final ValueChanged<bool> onMineOnlyChanged;
  final VoidCallback onClearFilters;

  const ComplaintFilterPanel({
    super.key,
    required this.searchController,
    required this.selectedStatus,
    required this.selectedPriority,
    required this.selectedType,
    required this.selectedEmployeeId,
    required this.mineOnly,
    required this.isAdmin,
    required this.employeesList,
    required this.activeFilterCount,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onTypeChanged,
    required this.onEmployeeChanged,
    required this.onMineOnlyChanged,
    required this.onClearFilters,
  });

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: color),
  );

  InputDecoration _decoration({bool active = false}) => InputDecoration(
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: _border(_line),
    enabledBorder: _border(active ? _accent : _line),
    focusedBorder: _border(_accent),
  );

  Widget _dropdown({
    required String? value,
    required String allLabel,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String?>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
      decoration: _decoration(active: value != null),
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: _ink,
      ),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(allLabel)),
        ...items,
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      style: const TextStyle(fontSize: 13.5),
      decoration: _decoration().copyWith(
        hintText: 'Search customer, phone or description',
        prefixIcon: const Icon(Icons.search, size: 20),
      ),
    );

    final status = _dropdown(
      value: selectedStatus,
      allLabel: 'All Status',
      items: ComplaintStatus.values
          .map(
            (s) => DropdownMenuItem<String?>(
              value: s.name,
              child: Text(s.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onStatusChanged,
    );

    final priority = _dropdown(
      value: selectedPriority,
      allLabel: 'All Priority',
      items: ComplaintPriority.values
          .map(
            (p) => DropdownMenuItem<String?>(
              value: p.name,
              child: Text(p.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onPriorityChanged,
    );

    final type = _dropdown(
      value: selectedType,
      allLabel: 'All Types',
      items: ComplaintType.values
          .map(
            (t) => DropdownMenuItem<String?>(
              value: t.name,
              child: Text(t.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onTypeChanged,
    );

    final assignee = _dropdown(
      value: selectedEmployeeId,
      allLabel: 'All Assignees',
      items: employeesList
          .map(
            (e) => DropdownMenuItem<String?>(
              value: e['id'] as String,
              child: Text(e['name'] as String, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onEmployeeChanged,
    );

    final clear = TextButton.icon(
      onPressed: onClearFilters,
      icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
      label: Text('Clear ($activeFilterCount)'),
      style: TextButton.styleFrom(
        foregroundColor: _accent,
        minimumSize: const Size(0, 44),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop: everything in one row.
        if (constraints.maxWidth >= 1000) {
          return Row(
            children: [
              Expanded(flex: 4, child: search),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: status),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: priority),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: type),
              if (isAdmin) ...[
                const SizedBox(width: 10),
                Expanded(flex: 2, child: assignee),
              ],
              if (activeFilterCount > 0) ...[const SizedBox(width: 6), clear],
            ],
          );
        }

        // Mobile / tablet: search, then dropdowns two per row.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            search,
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: status),
                const SizedBox(width: 10),
                Expanded(child: priority),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: type),
                if (isAdmin) ...[
                  const SizedBox(width: 10),
                  Expanded(child: assignee),
                ],
              ],
            ),
            if (activeFilterCount > 0)
              Align(alignment: Alignment.centerRight, child: clear),
          ],
        );
      },
    );
  }
}
