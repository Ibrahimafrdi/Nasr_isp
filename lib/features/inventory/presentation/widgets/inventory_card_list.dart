import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:nasr_isp/shared/widgets/info_chip.dart';

/// Mobile card list for the Inventory page.
///
/// NEW widget — the inventory page previously had no mobile layout.
/// Each card shows: item name, category, stock level (with color), unit cost,
/// status badge, and action buttons (adjust stock, edit, delete).
///
/// Pure UI — all callbacks received from parent page.
class InventoryCardList extends StatelessWidget {
  final List<InventoryItemEntity> items;

  /// Maps [InventoryCategory] to a display label.
  final String Function(InventoryCategory category) categoryLabel;

  final void Function(InventoryItemEntity item) onViewDetail;
  final void Function(InventoryItemEntity item) onAdjustStock;
  final void Function(InventoryItemEntity item) onEdit;
  final void Function(InventoryItemEntity item) onDelete;

  const InventoryCardList({
    super.key,
    required this.items,
    required this.categoryLabel,
    required this.onViewDetail,
    required this.onAdjustStock,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items
          .map((item) => _InventoryCard(
                item: item,
                categoryLabel: categoryLabel,
                onViewDetail: onViewDetail,
                onAdjustStock: onAdjustStock,
                onEdit: onEdit,
                onDelete: onDelete,
              ))
          .toList(),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItemEntity item;
  final String Function(InventoryCategory category) categoryLabel;
  final void Function(InventoryItemEntity item) onViewDetail;
  final void Function(InventoryItemEntity item) onAdjustStock;
  final void Function(InventoryItemEntity item) onEdit;
  final void Function(InventoryItemEntity item) onDelete;

  const _InventoryCard({
    required this.item,
    required this.categoryLabel,
    required this.onViewDetail,
    required this.onAdjustStock,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLow = item.quantityInStock <= item.reorderLevel;
    final statusText = item.quantityInStock == 0
        ? 'Out of Stock'
        : (isLow ? 'Low Stock' : 'Available');
    final statusColor = item.quantityInStock == 0
        ? AppTheme.errorColor
        : (isLow ? AppTheme.warningColor : AppTheme.successColor);

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
          // Header: item name + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onViewDetail(item),
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
                  statusText,
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
                Icons.category_outlined,
                categoryLabel(item.category),
              ),
              InfoChip(
                Icons.inventory_2_outlined,
                '${item.quantityInStock} ${item.unit}',
                color: statusColor,
              ),
              InfoChip(
                Icons.warning_amber_outlined,
                'Reorder: ${item.reorderLevel}',
              ),
              InfoChip(
                Icons.payments_outlined,
                'PKR ${item.unitCost.toStringAsFixed(0)}',
              ),
              InfoChip(
                Icons.sell_outlined,
                'PKR ${item.sellPrice.toStringAsFixed(0)}',
              ),
              InfoChip(
                item.connectionType == InventoryConnectionType.opticalFibre
                    ? Icons.cable
                    : Icons.wifi,
                item.connectionType.label,
                color: item.connectionType == InventoryConnectionType.opticalFibre
                    ? Colors.purple
                    : (item.connectionType == InventoryConnectionType.both
                        ? Colors.teal
                        : Colors.blue[800]),
              ),
            ],
          ),

          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Adjust', style: TextStyle(fontSize: 12)),
                onPressed: () => onAdjustStock(item),
              ),
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                onPressed: () => onEdit(item),
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                onPressed: () => onDelete(item),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
