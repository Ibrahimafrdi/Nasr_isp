import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/features/employees/domain/entities/employee_entity.dart';
import 'package:nasr_isp/shared/widgets/info_chip.dart';

/// Mobile card list for the Employees page.
///
/// Pure UI: all callbacks are supplied by the parent page.
class EmployeeCardList extends StatelessWidget {
  final List<EmployeeEntity> employees;
  final Map<String, int> installationCounts;
  final void Function(EmployeeEntity emp) onViewDetail;
  final void Function(EmployeeEntity emp) onEdit;
  final void Function(EmployeeEntity emp) onToggleStatus;

  const EmployeeCardList({
    super.key,
    required this.employees,
    required this.installationCounts,
    required this.onViewDetail,
    required this.onEdit,
    required this.onToggleStatus,
  });

  static const _ink = Color(0xFF14213D);
  static const _muted = Color(0xFF5B6472);
  static const _line = Color(0xFFC9CED6);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: employees.map((emp) {
        final subs = installationCounts[emp.id] ?? 0;
        final isInactive = emp.status == EmployeeStatus.inactive;
        final statusColor = isInactive
            ? AppTheme.errorColor
            : AppTheme.successColor;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3E6EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => onViewDetail(emp),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emp.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              emp.designation,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      emp.status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  InfoChip(Icons.location_on, emp.sectorArea),
                  InfoChip(Icons.phone, emp.phone),
                  InfoChip(Icons.people, '$subs assigned'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      foregroundColor: _ink,
                      side: const BorderSide(color: _line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => onEdit(emp),
                    child: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'More actions',
                    icon: const Icon(Icons.more_horiz),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    onSelected: (v) {
                      if (v == 'toggle') onToggleStatus(emp);
                      if (v == 'view') onViewDetail(emp);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Text('View profile'),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(
                          isInactive
                              ? 'Enable technician'
                              : 'Disable technician',
                          style: TextStyle(
                            color: isInactive ? null : AppTheme.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
