import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/shared/widgets/info_chip.dart';

/// Mobile card list for the Installations page.
///
/// NEW widget — the installations page previously had no mobile layout.
/// Each card shows: customer name, status badge, installer, installation date,
/// connection type, BOM summary, and (admin-only) cost info + edit/delete actions.
///
/// Pure UI — all callbacks received from parent page.
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
          .map((inst) => _InstallationCard(
                inst: inst,
                isAdmin: isAdmin,
                onEdit: onEdit,
                onDelete: onDelete,
              ))
          .toList(),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final statusColor = installationStatusColor(inst.status);
    final double cost = inst.materialCost ?? 0.0;
    final double fee = inst.installationCost;
    final double profit = inst.profit ?? 0.0;

    String bomText = 'No items logged';
    if (inst.itemsUsed != null && inst.itemsUsed!.isNotEmpty) {
      bomText = inst.itemsUsed!
          .map((i) => '${i.itemName} (x${i.quantity})')
          .join(', ');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGray.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: customer name + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  inst.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  inst.status.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Info chips
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              InfoChip(
                Icons.person_outline,
                inst.assignedEmployeeName ?? 'Unassigned',
              ),
              InfoChip(
                Icons.calendar_today,
                DateTimeUtils.formatDate(inst.installationDate),
              ),
              if (isAdmin) ...[
                InfoChip(
                  Icons.payments_outlined,
                  'Fee: ${DateTimeUtils.formatCurrency(fee)}',
                ),
                if (inst.materialCost != null)
                  InfoChip(
                    Icons.shopping_bag_outlined,
                    'Cost: ${DateTimeUtils.formatCurrency(cost)}',
                  ),
                if (inst.profit != null)
                  InfoChip(
                    Icons.account_balance_wallet_outlined,
                    'Profit: ${DateTimeUtils.formatCurrency(profit)}',
                    color: profit > 0
                        ? AppTheme.successColor
                        : (profit < 0 ? AppTheme.errorColor : null),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // BOM summary
          Text(
            'Materials: $bomText',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.mediumGray,
              fontStyle:
                  bomText == 'No items logged' ? FontStyle.italic : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (isAdmin) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  onPressed: () => onEdit(inst),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                  ),
                  onPressed: () => onDelete(inst),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
