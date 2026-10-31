import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/expenses/domain/entities/expense_entity.dart';

/// Mobile card list for the Expenses page.
///
/// Pure UI: all callbacks are received from the parent page.
class ExpenseCardList extends StatelessWidget {
  final List<ExpenseEntity> expenses;
  final bool isAdmin;
  final void Function(ExpenseEntity expense) onEdit;
  final void Function(ExpenseEntity expense) onDelete;

  const ExpenseCardList({
    super.key,
    required this.expenses,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  static const _ink = Color(0xFF14213D);
  static const _muted = Color(0xFF5B6472);
  static const _line = Color(0xFFC9CED6);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: expenses.map((e) {
        return Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      e.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _ink,
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
                      color: const Color(0xFFE6F2F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      e.category.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B5B55),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                DateTimeUtils.formatCurrency(e.amount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Paid by ${e.paidBy} · ${DateTimeUtils.formatDate(e.date)}',
                style: const TextStyle(fontSize: 13, color: _muted),
              ),
              if (e.notes != null && e.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  e.notes!,
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
              ],
              if (isAdmin) ...[
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
                      onPressed: () => onEdit(e),
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
                        if (v == 'delete') onDelete(e);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete expense',
                            style: TextStyle(color: AppTheme.errorColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
