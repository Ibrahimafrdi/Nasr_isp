import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';

/// Mobile card list for the Installations page.
///
/// Pure UI: all callbacks are received from the parent page.
class InstallationCardList extends StatelessWidget {
  final List<InstallationEntity> installations;
  final bool isAdmin;
  final void Function(InstallationEntity inst) onEdit;
  final void Function(InstallationEntity inst) onDelete;

  const InstallationCardList({
    super.key,
    required this.installations,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: installations
          .map(
            (inst) => _InstallationCard(
              inst: inst,
              isAdmin: isAdmin,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          )
          .toList(),
    );
  }
}

/// Used by both the page table and these cards.
Color installationStatusColor(InstallationStatus status) {
  switch (status) {
    case InstallationStatus.pending:
      return AppTheme.warningColor;
    case InstallationStatus.inProgress:
      return AppColors.primaryBlue;
    case InstallationStatus.completed:
      return AppTheme.successColor;
    case InstallationStatus.cancelled:
      return AppTheme.errorColor;
  }
}

class _InstallationCard extends StatelessWidget {
  final InstallationEntity inst;
  final bool isAdmin;
  final void Function(InstallationEntity inst) onEdit;
  final void Function(InstallationEntity inst) onDelete;

  const _InstallationCard({
    required this.inst,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  static const _ink = Color(0xFF14213D);
  static const _muted = Color(0xFF5B6472);
  static const _line = Color(0xFFC9CED6);

  Widget _moneyLine(
    String label,
    String value, {
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _muted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? _ink,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = installationStatusColor(inst.status);
    // Same MoneyLine the desktop table uses, so the two layouts can't drift.
    final money = inst.money;

    String bomText = 'No items logged';
    if (inst.itemsUsed != null && inst.itemsUsed!.isNotEmpty) {
      bomText = inst.itemsUsed!
          .map((i) => '${i.itemName} (x${i.quantity})')
          .join(', ');
    }

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
                  inst.customerName,
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
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  inst.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${inst.assignedEmployeeName ?? 'Unassigned'} · '
            '${DateTimeUtils.formatDate(inst.installationDate)}',
            style: const TextStyle(fontSize: 13, color: _muted),
          ),
          const SizedBox(height: 6),
          Text(
            'Materials: $bomText',
            style: TextStyle(
              fontSize: 13,
              color: _muted,
              fontStyle: bomText == 'No items logged' ? FontStyle.italic : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            _moneyLine(
              'Billed',
              DateTimeUtils.formatCurrency(money.amountBilled),
            ),
            if (inst.hasCostData)
              _moneyLine(
                'Cost',
                DateTimeUtils.formatCurrency(money.costIncurred),
              ),
            _moneyLine(
              'Profit',
              DateTimeUtils.formatCurrency(money.profit),
              bold: true,
              // Uncoloured when no costs were logged: the figure is exact
              // but assumes zero cost, so it shouldn't read as a win.
              color: !inst.hasCostData
                  ? null
                  : (money.profit > 0
                        ? AppTheme.successColor
                        : (money.profit < 0 ? AppTheme.errorColor : null)),
            ),
            const SizedBox(height: 8),
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
                  onPressed: () => onEdit(inst),
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
                    if (v == 'delete') onDelete(inst);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete log',
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
  }
}
