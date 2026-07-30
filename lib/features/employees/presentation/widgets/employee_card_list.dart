import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/features/employees/domain/entities/employee_entity.dart';
import 'package:nasr_isp/shared/widgets/info_chip.dart';

/// Mobile card list for the Employees page.
///
/// Pure UI — all callbacks are supplied by the parent page.
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: employees.map((emp) {
        final subs = installationCounts[emp.id] ?? 0;
        final isInactive = emp.status == EmployeeStatus.inactive;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.veryLightGray,
            borderRadius: BorderRadius.circular(10),
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
                        // Lifts the tap target to ~44dp; the bare Text was 17dp.
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          emp.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isInactive 
                          ? AppTheme.errorColor.withOpacity(0.1) 
                          : AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      emp.status.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isInactive ? AppTheme.errorColor : AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                emp.designation,
                style: const TextStyle(fontSize: 12, color: AppTheme.mediumGray),
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
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: AppTheme.primaryColor),
                    onPressed: () => onEdit(emp),
                  ),
                  IconButton(
                    icon: Icon(
                      isInactive ? Icons.check_circle_outline : Icons.block,
                      size: 18,
                      color: isInactive ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                    onPressed: () => onToggleStatus(emp),
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
