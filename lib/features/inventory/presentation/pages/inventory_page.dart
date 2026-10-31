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
  bool _lowStockOnly = false;

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
      _lowStockOnly = false;
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
                            final authState =
                                pageContext.read<AuthBloc>().state;
                            final performer = authState is AuthAuthenticated
                                ? (authState.user.name.isNotEmpty
                                    ? authState.user.name
                                    : (authState.user.email.isNotEmpty
                                        ? authState.user.email
                                        : authState.user.id))
                                : null;
                            bloc.add(AddInventoryItemEvent(
                              item,
                              performedBy: performer,
                            ));
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

  static const _accent = Color(0xFF0F766E);
  static const _ink = Color(0xFF14213D);
  static const _muted = Color(0xFF5B6472);
  static const _border = Color(0xFFE3E6EB);

  /// Rs 450,000 style.
  String _rs(num amount) {
    final digits = amount.round().toString();
    final withCommas = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return 'Rs $withCommas';
  }

  Widget _statCard(String label, String value, {String? note, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color ?? _ink,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note, style: const TextStyle(fontSize: 12, color: _muted)),
          ],
        ],
      ),
    );
  }

  Widget _cardGrid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 16.0;
        final cols = c.maxWidth >= 900 ? 4 : 2;
        final width = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }

  Widget _buildRestockBar(
    BuildContext context,
    List<InventoryItemEntity> lowStockItems,
  ) {
    const brown = Color(0xFF7A3E00);
    final worst = ([...lowStockItems]
      ..sort((a, b) => a.quantityInStock.compareTo(b.quantityInStock)))
        .first;
    final more = lowStockItems.length - 1;
    final text = worst.quantityInStock <= 0
        ? '${worst.name} is out of stock (reorder at ${worst.reorderLevel})'
        : '${worst.name} has ${worst.quantityInStock} left (reorder at ${worst.reorderLevel})';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2C98A)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 14, color: brown),
              children: [
                const TextSpan(
                  text: 'Restock soon: ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: more > 0 ? '$text and $more more.' : '$text.',
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: brown,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => _showAdjustStockDialog(context, worst),
            child: const Text('Add stock'),
          ),
        ],
      ),
    );
  }

  // ---------- Desktop table ----------

  static const _flex = [22, 16, 10, 10, 12, 11, 24];

  Widget _tableRow(List<Widget> cells, {bool header = false, bool last = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: header ? 12 : 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEEF0F3))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: _flex[i],
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: cells[i],
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerCell(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _muted,
        ),
      );

  Widget _buildItemsTable(
    BuildContext context,
    List<InventoryItemEntity> items,
  ) {
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth < 980 ? 980.0 : c.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                _tableRow([
                  _headerCell('Item'),
                  _headerCell('In stock'),
                  _headerCell('Unit cost'),
                  _headerCell('Sell price'),
                  _headerCell('Profit per unit'),
                  _headerCell('Status'),
                  _headerCell('Actions'),
                ], header: true),
                for (var i = 0; i < items.length; i++)
                  _itemRow(context, items[i], last: i == items.length - 1),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _itemRow(
    BuildContext context,
    InventoryItemEntity item, {
    required bool last,
  }) {
    final isOut = item.quantityInStock <= 0;
    final isLow = !isOut && item.quantityInStock <= item.reorderLevel;
    final statusText =
        isOut ? 'Out of stock' : (isLow ? 'Low stock' : 'Available');
    final statusColor = isOut
        ? AppTheme.errorColor
        : (isLow ? AppTheme.warningColor : AppTheme.successColor);
    final unitLabel = item.unit.trim().isEmpty ? 'pcs' : item.unit;
    final ratio = item.reorderLevel <= 0
        ? (isOut ? 0.0 : 1.0)
        : (item.quantityInStock / (item.reorderLevel * 2)).clamp(0.0, 1.0);
    final profit = item.sellPrice - item.unitCost;
    final pct = item.sellPrice > 0 ? (profit / item.sellPrice * 100).round() : null;

    ButtonStyle btn(Color fg, Color border) => OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      foregroundColor: fg,
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );

    return _tableRow([
      InkWell(
        onTap: () => _showItemDetail(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${_categoryLabel(item.category)} · ${item.connectionType.label}',
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.quantityInStock} $unitLabel',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isOut || isLow ? statusColor : _ink,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: _border,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOut || isLow ? statusColor : _accent,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reorder at ${item.reorderLevel}',
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
        ],
      ),
      Text(_rs(item.unitCost)),
      Text(_rs(item.sellPrice)),
      Text(
        pct == null ? _rs(profit) : '${_rs(profit)} ($pct%)',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: profit >= 0 ? AppTheme.successColor : AppTheme.errorColor,
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton(
            style: btn(_accent, _accent),
            onPressed: () => _showAdjustStockDialog(context, item),
            child: const Text('Adjust stock'),
          ),
          OutlinedButton(
            style: btn(_ink, const Color(0xFFC9CED6)),
            onPressed: () => _showItemDialog(context, existing: item),
            child: const Text('Edit'),
          ),
          PopupMenuButton<String>(
            tooltip: 'More actions',
            icon: const Icon(Icons.more_horiz),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onSelected: (v) {
              if (v == 'delete') _confirmDelete(context, item);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete item',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ],
          ),
        ],
      ),
    ], last: last);
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
              final matchesLow =
                  !_lowStockOnly || item.quantityInStock <= item.reorderLevel;
              return matchesSearch &&
                  matchesCategory &&
                  matchesConnectionType &&
                  matchesLow;
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

            final sellValue = allItems.fold(
              0.0,
              (sum, i) => sum + (i.sellPrice * i.quantityInStock),
            );
            final activeFilters =
                (_selectedCategory != null ? 1 : 0) +
                (_selectedConnectionType != null ? 1 : 0) +
                (_searchController.text.isNotEmpty ? 1 : 0) +
                (_lowStockOnly ? 1 : 0);

            return SingleChildScrollView(
              padding: Responsive.pagePaddingFor(Responsive.deviceTypeOf(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventory',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Know what you have, what is running low, and what it is worth.',
                              style: TextStyle(fontSize: 14, color: _muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _showItemDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add item'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _cardGrid([
                    _statCard('Items tracked', '${allItems.length}'),
                    _statCard(
                      'Needs restocking',
                      '${lowStockItems.length}',
                      note: 'Low or out of stock',
                      color: lowStockItems.isNotEmpty
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                    ),
                    _statCard(
                      'Stock value (what you paid)',
                      _rs(totalValue),
                      note: 'Worth ${_rs(sellValue)} at sell price',
                    ),
                    _statCard(
                      'Equipment units',
                      '$totalEquipment',
                      note: 'Routers, ONUs and similar',
                    ),
                  ]),
                  if (lowStockItems.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildRestockBar(context, lowStockItems),
                  ],
                  const SizedBox(height: 24),
                  InventoryFilterPanel(
                    searchController: _searchController,
                    selectedCategory: _selectedCategory,
                    selectedConnectionType: _selectedConnectionType,
                    lowStockOnly: _lowStockOnly,
                    activeFilterCount: activeFilters,
                    categoryLabel: _categoryLabel,
                    onSearchChanged: (_) => setState(() {}),
                    onCategoryChanged: (cat) =>
                        setState(() => _selectedCategory = cat),
                    onConnectionTypeChanged: (type) =>
                        setState(() => _selectedConnectionType = type),
                    onLowStockOnlyChanged: (v) =>
                        setState(() => _lowStockOnly = v),
                    onClearFilters: _clearFilters,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                          desktop: _buildItemsTable(context, filteredItems),
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
