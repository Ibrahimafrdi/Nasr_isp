import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:nasr_isp/config/service_locator.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/utils/input_formatters.dart';
import 'package:nasr_isp/core/constants/inventory_catalog.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
import 'package:nasr_isp/shared/widgets/adaptive_form_dialog.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:nasr_isp/features/inventory/domain/entities/stock_movement_entity.dart';
import 'package:nasr_isp/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:nasr_isp/features/inventory/presentation/widgets/inventory_card_list.dart';
import 'package:nasr_isp/features/inventory/presentation/widgets/inventory_filter_panel.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<InventoryBloc>()..add(LoadInventoryItems()),
      child: const _InventoryView(),
    );
  }
}

class _InventoryView extends StatefulWidget {
  const _InventoryView();

  @override
  State<_InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<_InventoryView> {
  late TextEditingController _searchController;
  InventoryCategory? _selectedCategory;
  InventoryConnectionType? _selectedConnectionType;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedConnectionType = null;
    });
  }

  String _categoryLabel(InventoryCategory c) =>
      c == InventoryCategory.equipment ? 'Equipment' : 'Consumable';

  // ---------- Add / Edit Item Dialog ----------

  void _showItemDialog(
    BuildContext pageContext, {
    InventoryItemEntity? existing,
  }) {
    final bloc = pageContext.read<InventoryBloc>();
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name ?? '');
    final unitController = TextEditingController(text: existing?.unit ?? 'pcs');
    final quantityController = TextEditingController(
      text: existing != null ? existing.quantityInStock.toString() : '',
    );
    final reorderController = TextEditingController(
      text: existing != null ? existing.reorderLevel.toString() : '',
    );
    final unitCostController = TextEditingController(
      text: existing != null ? existing.unitCost.toString() : '',
    );
    final sellPriceController = TextEditingController(
      text: existing != null ? existing.sellPrice.toString() : '',
    );
    final supplierController = TextEditingController(
      text: existing?.supplier ?? '',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    InventoryCategory category =
        existing?.category ?? InventoryCategory.equipment;
    InventoryConnectionType connectionType =
        existing?.connectionType ?? InventoryConnectionType.both;
    bool isSaving = false;

    showAppFormDialog(
      context: pageContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AdaptiveFormDialog(
              title: existing == null
                  ? 'Add Inventory Item'
                  : 'Edit Inventory Item',
              desktopWidth: 420,
              canClose: !isSaving,
              onClose: () => Navigator.pop(dialogContext),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (existing == null)
                      Autocomplete<InventoryCatalogEntry>(
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return kInventoryCatalog;
                          }
                          final query = textEditingValue.text.toLowerCase();
                          return kInventoryCatalog.where(
                            (entry) => entry.name.toLowerCase().contains(query),
                          );
                        },
                        displayStringForOption: (entry) => entry.name,
                        fieldViewBuilder: (ctx, textController, focusNode, _) {
                          if (textController.text.isEmpty &&
                              nameController.text.isNotEmpty) {
                            textController.text = nameController.text;
                          }
                          return TextFormField(
                            controller: textController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Item Name',
                              hintText: 'Pick from catalog or type a new item',
                              suffixIcon: Icon(Icons.search, size: 18),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Name required' : null,
                            onChanged: (v) => nameController.text = v,
                          );
                        },
                        onSelected: (entry) {
                          nameController.text = entry.name;
                          setDialogState(() {
                            category = entry.category;
                            connectionType = entry.connectionType;
                            unitController.text = entry.unit;
                            unitCostController.text = entry.unitCost.toString();
                            if (sellPriceController.text.isEmpty) {
                              sellPriceController.text = entry.unitCost
                                  .toString();
                            }
                            if (quantityController.text.isEmpty) {
                              quantityController.text = entry.quantityInStock
                                  .toString();
                            }
                            if (reorderController.text.isEmpty) {
                              reorderController.text = entry.reorderLevel
                                  .toString();
                            }
                          });
                        },
                      )
                    else
                      AppFormField(
                        label: 'Item Name',
                        controller: nameController,
                        hintText: 'e.g. TP-Link Router AC1200',
                        isRequired: true,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Name required' : null,
                      ),
                    const SizedBox(height: 16),
                    if (existing == null)
                      BlocBuilder<InventoryBloc, InventoryState>(
                        bloc: bloc,
                        builder: (_, state) {
                          if (state is! InventoryLoaded) return const SizedBox.shrink();
                          return ValueListenableBuilder<TextEditingValue>(
                            valueListenable: nameController,
                            builder: (__, nameValue, ___) {
                              final typedName = nameValue.text.trim().toLowerCase();
                              if (typedName.isEmpty) return const SizedBox.shrink();
                              final match = state.items.where(
                                (i) => i.name.trim().toLowerCase() == typedName,
                              );
                              if (match.isEmpty) return const SizedBox.shrink();
                              final found = match.first;
                              final unitLabel = found.unit.trim().isEmpty ? 'pcs' : found.unit;
                              final curQty = found.quantityInStock <= 0
                                  ? '0 $unitLabel'
                                  : '${found.quantityInStock} $unitLabel';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'This item already exists (current stock: $curQty). '
                                        'Saving will add quantity to the existing stock.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    DropdownButtonFormField<InventoryCategory>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: InventoryCategory.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(_categoryLabel(c)),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<InventoryConnectionType>(
                      value: connectionType,
                      decoration: const InputDecoration(
                        labelText: 'Applicable To',
                      ),
                      items: InventoryConnectionType.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.label),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => connectionType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    AppFormField(
                      label: 'Unit',
                      controller: unitController,
                      hintText: 'pcs / meters / box',
                      isRequired: true,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Unit required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppFormField(
                      label: 'Quantity in Stock',
                      controller: quantityController,
                      hintText: 'e.g. 10',
                      keyboardType: TextInputType.number,
                      inputFormatters: AppInputFormatters.integer,
                      isRequired: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Quantity required';
                        if (int.tryParse(v) == null || int.parse(v) < 0)
                          return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppFormField(
                      label: 'Reorder Level',
                      controller: reorderController,
                      hintText: 'e.g. 5',
                      keyboardType: TextInputType.number,
                      inputFormatters: AppInputFormatters.integer,
                      isRequired: true,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Reorder level required';
                        if (int.tryParse(v) == null || int.parse(v) < 0)
                          return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppFormField(
                      label: 'Unit Cost',
                      controller: unitCostController,
                      hintText: 'e.g. 4500',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: AppInputFormatters.decimal,
                      isRequired: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Unit cost required';
                        if (double.tryParse(v) == null)
                          return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppFormField(
                      label: 'Sell Price',
                      controller: sellPriceController,
                      hintText: 'Price billed to the customer, e.g. 5000',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: AppInputFormatters.decimal,
                      isRequired: true,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Sell price required';
                        if (double.tryParse(v) == null)
                          return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppFormField(
                      label: 'Supplier',
                      controller: supplierController,
                      hintText: 'Optional',
                    ),
                    const SizedBox(height: 16),
                    AppFormField(
                      label: 'Notes',
                      controller: notesController,
                      hintText: 'Optional',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.mediumGray),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);

                          final now = DateTime.now();
                          final item = InventoryItemEntity(
                            id: existing?.id ?? const Uuid().v4(),
                            name: nameController.text.trim(),
                            category: category,
                            unit: unitController.text.trim(),
                            quantityInStock: int.parse(quantityController.text),
                            reorderLevel: int.parse(reorderController.text),
                            unitCost: double.parse(unitCostController.text),
                            sellPrice: double.parse(sellPriceController.text),
                            supplier: supplierController.text.trim().isEmpty
                                ? null
                                : supplierController.text.trim(),
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                            createdAt: existing?.createdAt ?? now,
                            updatedAt: now,
                            connectionType: connectionType,
                          );
                          if (existing == null) {
                            bloc.add(AddInventoryItemEvent(item));
                          } else {
                            bloc.add(UpdateInventoryItemEvent(item));
                          }

                          final result = await bloc.stream.firstWhere(
                            (s) => s is InventoryLoaded || s is InventoryError,
                          );

                          if (!pageContext.mounted) return;

                          if (result is InventoryError) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to save item: ${result.message}',
                                ),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                existing == null
                                    ? 'Item added'
                                    : 'Item updated',
                              ),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        },
                  child: Text(isSaving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- Adjust Stock Dialog ----------

  void _showAdjustStockDialog(
    BuildContext pageContext,
    InventoryItemEntity item,
  ) {
    final bloc = pageContext.read<InventoryBloc>();
    final formKey = GlobalKey<FormState>();
    final qtyController = TextEditingController();
    StockMovementType type = StockMovementType.stockIn;
    String reason = 'Purchase';
    bool isSaving = false;

    const reasons = [
      'Purchase',
      'Used in installation',
      'Damaged',
      'Adjustment',
    ];

    showAppFormDialog(
      context: pageContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AdaptiveFormDialog(
              title: 'Adjust Stock — ${item.name}',
              desktopWidth: 380,
              canClose: !isSaving,
              onClose: () => Navigator.pop(dialogContext),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Current stock: ${item.quantityInStock} ${item.unit}',
                      style: const TextStyle(color: AppTheme.mediumGray),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<StockMovementType>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'Movement Type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: StockMovementType.stockIn,
                          child: Text('Stock In (+)'),
                        ),
                        DropdownMenuItem(
                          value: StockMovementType.stockOut,
                          child: Text('Stock Out (-)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => type = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    AppFormField(
                      label: 'Quantity',
                      controller: qtyController,
                      hintText: 'e.g. 10',
                      keyboardType: TextInputType.number,
                      inputFormatters: AppInputFormatters.integer,
                      isRequired: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Quantity required';
                        final n = int.tryParse(v);
                        if (n == null || n <= 0)
                          return 'Enter a valid positive number';
                        if (type == StockMovementType.stockOut &&
                            n > item.quantityInStock) {
                          return 'Cannot remove more than current stock (${item.quantityInStock})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: reason,
                      decoration: const InputDecoration(labelText: 'Reason'),
                      items: reasons
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => reason = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.mediumGray),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);

                          final authState = pageContext.read<AuthBloc>().state;
                          final userId = authState is AuthAuthenticated
                              ? authState.user.id
                              : 'unknown';
                          final movement = StockMovementEntity(
                            id: const Uuid().v4(),
                            itemId: item.id,
                            type: type,
                            quantity: int.parse(qtyController.text),
                            reason: reason,
                            date: DateTime.now(),
                            performedBy: userId,
                          );
                          bloc.add(AddStockMovementEvent(item.id, movement));

                          final result = await bloc.stream.firstWhere(
                            (s) => s is InventoryLoaded || s is InventoryError,
                          );

                          if (!pageContext.mounted) return;

                          if (result is InventoryError) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to update stock: ${result.message}',
                                ),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            const SnackBar(
                              content: Text('Stock updated'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        },
                  child: Text(isSaving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext pageContext, InventoryItemEntity item) {
    final bloc = pageContext.read<InventoryBloc>();
    bool isDeleting = false;
    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Delete Item'),
              content: Text(
                'Delete "${item.name}" and all its stock history? This cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          bloc.add(DeleteInventoryItemEvent(item.id));

                          final result = await bloc.stream.firstWhere(
                            (s) => s is InventoryLoaded || s is InventoryError,
                          );

                          if (!pageContext.mounted) return;

                          if (result is InventoryError) {
                            setDialogState(() => isDeleting = false);
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to delete item: ${result.message}',
                                ),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            const SnackBar(
                              content: Text('Item deleted'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        },
                  child: Text(isDeleting ? 'Deleting...' : 'Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- Item Detail Side Sheet ----------

  void _showItemDetail(BuildContext pageContext, InventoryItemEntity item) {
    pageContext.read<InventoryBloc>().add(LoadStockMovements(item.id));
    showGeneralDialog(
      context: pageContext,
      barrierDismissible: true,
      barrierLabel: 'Item Detail',
      pageBuilder: (_, __, ___) {
        // A 420dp side sheet has nowhere to sit on a phone — it would clamp
        // to the full width anyway, so make that explicit rather than
        // rendering a "side" sheet that covers everything.
        final isMobile = Responsive.isMobile(pageContext);

        return Align(
          alignment: isMobile ? Alignment.center : Alignment.centerRight,
          child: Material(
            child: Container(
              width: isMobile ? double.infinity : 420,
              height: double.infinity,
              color: AppTheme.whiteColor,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(pageContext),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('Category: ${_categoryLabel(item.category)}'),
                      const SizedBox(height: 4),
                       Builder(builder: (context) {
                         final unitLabel = item.unit.trim().isEmpty ? 'pcs' : item.unit;
                         final qtyDisplay = item.quantityInStock <= 0
                             ? '0 $unitLabel — Out of Stock'
                             : '${item.quantityInStock} $unitLabel';
                         final qtyColor = item.quantityInStock <= 0
                             ? AppTheme.errorColor
                             : null;
                         return Text(
                           'Quantity in Stock: $qtyDisplay',
                           style: TextStyle(
                             color: qtyColor,
                             fontWeight: item.quantityInStock <= 0
                                 ? FontWeight.bold
                                 : FontWeight.normal,
                           ),
                         );
                       }),
                      const SizedBox(height: 4),
                      Text('Reorder Level: ${item.reorderLevel} ${item.unit}'),
                      const SizedBox(height: 4),
                      Text(
                        'Unit Cost: PKR ${item.unitCost.toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sell Price: PKR ${item.sellPrice.toStringAsFixed(0)}',
                      ),
                      if (item.supplier != null &&
                          item.supplier!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Supplier: ${item.supplier}'),
                      ],
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Notes: ${item.notes}'),
                      ],
                      const SizedBox(height: 20),
                      const Text(
                        'Stock Movement History',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: BlocBuilder<InventoryBloc, InventoryState>(
                          builder: (context, state) {
                            if (state is StockMovementsLoaded &&
                                state.itemId == item.id) {
                              if (state.movements.isEmpty) {
                                return const Center(
                                  child: Text('No movements recorded yet.'),
                                );
                              }
                              return ListView.builder(
                                itemCount: state.movements.length,
                                itemBuilder: (context, index) {
                                  final m = state.movements[index];
                                  final isIn =
                                      m.type == StockMovementType.stockIn;
                                  return ListTile(
                                    dense: true,
                                    leading: Icon(
                                      isIn
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: isIn
                                          ? AppTheme.successColor
                                          : AppTheme.errorColor,
                                    ),
                                    title: Text(
                                      '${isIn ? '+' : '-'}${m.quantity} ${item.unit} — ${m.reason}',
                                    ),
                                    subtitle: Text(
                                      '${m.date.toLocal()}'.split('.').first,
                                    ),
                                  );
                                },
                              );
                            }
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.mediumGray,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: Text('Not authenticated'));
        }

        return BlocConsumer<InventoryBloc, InventoryState>(
          listener: (context, state) {
            if (state is InventoryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is InventoryLoading || state is InventoryInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            List<InventoryItemEntity> allItems = [];
            List<InventoryItemEntity> lowStockItems = [];
            if (state is InventoryLoaded) {
              allItems = state.items;
              lowStockItems = state.lowStockItems;
            }

            final filteredItems = allItems.where((item) {
              final matchesSearch = item.name.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              );
              final matchesCategory =
                  _selectedCategory == null ||
                  item.category == _selectedCategory;
              final matchesConnectionType =
                  _selectedConnectionType == null ||
                  item.connectionType == _selectedConnectionType;
              return matchesSearch && matchesCategory && matchesConnectionType;
            }).toList();

            final totalEquipment = allItems
                .where((i) => i.category == InventoryCategory.equipment)
                .fold(0, (sum, i) => sum + i.quantityInStock);
            final totalConsumables = allItems
                .where((i) => i.category == InventoryCategory.consumable)
                .fold(0, (sum, i) => sum + i.quantityInStock);
            final totalValue = allItems.fold(
              0.0,
              (sum, i) => sum + (i.unitCost * i.quantityInStock),
            );

            return SingleChildScrollView(
              padding: Responsive.pagePaddingFor(Responsive.deviceTypeOf(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Breadcrumb(
                    items: [
                      BreadcrumbItem(
                        label: 'Home',
                        onTap: () => context.go(RoutePaths.dashboard),
                      ),
                      BreadcrumbItem(label: 'Inventory'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventory Management',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track equipment and consumable stock levels.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showItemDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 800;
                      return GridView.count(
                        crossAxisCount: isDesktop ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: isDesktop ? 1.8 : 1.3,
                        children: [
                          _buildMetricCard(
                            'Total Items',
                            '${allItems.length}',
                            'Tracked SKUs',
                            Icons.inventory_2,
                            AppTheme.primaryColor,
                          ),
                          _buildMetricCard(
                            'Low Stock Alerts',
                            '${lowStockItems.length} Items',
                            'At or below reorder level',
                            Icons.warning_amber_rounded,
                            lowStockItems.isNotEmpty
                                ? AppTheme.errorColor
                                : AppTheme.successColor,
                          ),
                          _buildMetricCard(
                            'Equipment Stock',
                            '$totalEquipment',
                            'Units available',
                            Icons.router,
                            Colors.purple,
                          ),
                          _buildMetricCard(
                            'Stock Value',
                            'PKR ${totalValue.toStringAsFixed(0)}',
                            'Total inventory cost',
                            Icons.payments,
                            Colors.teal,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  InventoryFilterPanel(
                    searchController: _searchController,
                    selectedCategory: _selectedCategory,
                    selectedConnectionType: _selectedConnectionType,
                    activeFilterCount:
                        (_selectedCategory != null ? 1 : 0) +
                        (_selectedConnectionType != null ? 1 : 0) +
                        (_searchController.text.isNotEmpty ? 1 : 0),
                    categoryLabel: _categoryLabel,
                    onSearchChanged: (_) => setState(() {}),
                    onCategoryChanged: (cat) =>
                        setState(() => _selectedCategory = cat),
                    onConnectionTypeChanged: (type) =>
                        setState(() => _selectedConnectionType = type),
                    onClearFilters: _clearFilters,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Inventory Directory',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Divider(),
                        ResponsiveSwitcher(
                          mobile: InventoryCardList(
                            items: filteredItems,
                            categoryLabel: _categoryLabel,
                            onViewDetail: (item) =>
                                _showItemDetail(context, item),
                            onAdjustStock: (item) =>
                                _showAdjustStockDialog(context, item),
                            onEdit: (item) =>
                                _showItemDialog(context, existing: item),
                            onDelete: (item) => _confirmDelete(context, item),
                          ),
                          desktop: DataTableWrapper(
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Category')),
                              DataColumn(label: Text('Used For')),
                              DataColumn(label: Text('Quantity')),
                              DataColumn(label: Text('Reorder Level')),
                              DataColumn(label: Text('Unit Cost')),
                              DataColumn(label: Text('Sell Price')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: filteredItems.map((item) {
                              final isOut = item.quantityInStock <= 0;
                              final isLow = !isOut && item.quantityInStock <= item.reorderLevel;
                              final statusText = isOut
                                  ? 'Out of Stock'
                                  : (isLow ? 'Low Stock' : 'Available');
                              final statusColor = isOut
                                  ? AppTheme.errorColor
                                  : (isLow
                                        ? AppTheme.warningColor
                                        : AppTheme.successColor);
                              final unitLabel = item.unit.trim().isEmpty ? 'pcs' : item.unit;
                              final qtyDisplay = isOut ? '0 $unitLabel' : '${item.quantityInStock} $unitLabel';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onTap: () => _showItemDetail(context, item),
                                  ),
                                  DataCell(Text(_categoryLabel(item.category))),
                                  DataCell(Text(item.connectionType.label)),
                                  DataCell(
                                    Text(
                                      qtyDisplay,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text('${item.reorderLevel} ${item.unit}'),
                                  ),
                                  DataCell(
                                    Text(
                                      'PKR ${item.unitCost.toStringAsFixed(0)}',
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      'PKR ${item.sellPrice.toStringAsFixed(0)}',
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.tune,
                                            size: 18,
                                          ),
                                          tooltip: 'Adjust Stock',
                                          onPressed: () =>
                                              _showAdjustStockDialog(
                                                context,
                                                item,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 18,
                                          ),
                                          tooltip: 'Edit',
                                          onPressed: () => _showItemDialog(
                                            context,
                                            existing: item,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: AppTheme.errorColor,
                                          ),
                                          tooltip: 'Delete',
                                          onPressed: () =>
                                              _confirmDelete(context, item),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        if (filteredItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text('No matching items found.'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
