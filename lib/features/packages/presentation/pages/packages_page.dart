import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/auth_helpers.dart';
import 'package:nasr_isp/core/utils/input_formatters.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_bloc.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_event.dart';
import 'package:nasr_isp/features/packages/presentation/bloc/packages_state.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class PackagesPage extends StatefulWidget {
  const PackagesPage({super.key});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  ConnectionType? _filterType;
  bool _activeOnly = false;

  void _reload() {
    context.read<PackagesBloc>().add(
          LoadPackages(filterByType: _filterType, activeOnly: _activeOnly ? true : null),
        );
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: Text('Not authenticated'));
        }
        final isAdmin = AuthHelpers.isAdmin(authState.user);

        return BlocConsumer<PackagesBloc, PackagesState>(
          listener: (context, state) {
            if (state is PackageActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            } else if (state is PackagesError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ───────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Breadcrumb(
                          items: [
                            BreadcrumbItem(
                              label: 'Home',
                              onTap: () => context.go(RoutePaths.dashboard),
                            ),
                            BreadcrumbItem(label: 'Packages'),
                          ],
                        ),
                      ),
                      if (isAdmin)
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showPackageFormSheet(context, isAdmin: isAdmin),
                          icon: const Icon(Icons.add, size: 18, color: Colors.white),
                          label: const Text('Add Package'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Filter bar ───────────────────────────────────────────
                  _buildFilterBar(),
                  const SizedBox(height: 20),

                  // ── Content ──────────────────────────────────────────────
                  if (state is PackagesLoading)
                    const LoadingWidget(message: 'Loading packages...')
                  else if (state is PackagesError)
                    _buildError(state.message)
                  else if (state is PackagesLoaded)
                    state.packages.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.wifi_off,
                            title: 'No Packages Found',
                            subtitle: 'Add a new package to begin.',
                          )
                        : ResponsiveSwitcher(
                            mobile: _buildCardGrid(
                                state.packages, isAdmin, 1),
                            tablet: _buildCardGrid(
                                state.packages, isAdmin, 2),
                            desktop: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: _buildTable(
                                    state.packages, isAdmin, context),
                              ),
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

  // ── Filter bar ─────────────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Connection type filter
        DropdownButtonHideUnderline(
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<ConnectionType?>(
              value: _filterType,
              hint: const Text('All Types', style: TextStyle(fontSize: 13)),
              onChanged: (v) {
                setState(() => _filterType = v);
                _reload();
              },
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ...ConnectionType.values.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.label),
                    )),
              ],
            ),
          ),
        ),

        // Active-only toggle
        FilterChip(
          label: const Text('Active Only', style: TextStyle(fontSize: 12)),
          selected: _activeOnly,
          onSelected: (v) {
            setState(() => _activeOnly = v);
            _reload();
          },
          selectedColor: AppColors.primaryBlue.withValues(alpha: 0.12),
          checkmarkColor: AppColors.primaryBlue,
        ),

        // Clear filters
        if (_filterType != null || _activeOnly)
          TextButton.icon(
            icon: const Icon(Icons.clear, size: 14),
            label: const Text('Clear', style: TextStyle(fontSize: 12)),
            onPressed: () {
              setState(() {
                _filterType = null;
                _activeOnly = false;
              });
              _reload();
            },
          ),
      ],
    );
  }

  // ── Desktop table ──────────────────────────────────────────────────────────

  Widget _buildTable(
      List<PackageEntity> packages, bool isAdmin, BuildContext ctx) {
    return DataTableWrapper(
      columns: [
        const DataColumn(label: Text('Package Name')),
        const DataColumn(label: Text('Type')),
        const DataColumn(label: Text('Speed')),
        if (isAdmin) const DataColumn(label: Text('Buy Price')),
        if (isAdmin) const DataColumn(label: Text('Sell Price / mo')),
        if (isAdmin) const DataColumn(label: Text('Profit')),
        const DataColumn(label: Text('Status')),
        if (isAdmin) const DataColumn(label: Text('Actions')),
      ],
      rows: packages.map((pkg) {
        return DataRow(
          cells: [
            DataCell(Text(pkg.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor))),
            DataCell(_connectionChip(pkg.connectionType)),
            DataCell(_speedChip(pkg.speedMbps)),
            if (isAdmin)
              DataCell(Text('PKR ${pkg.costPrice.toStringAsFixed(0)}')),
            if (isAdmin)
              DataCell(Text(
                'PKR ${pkg.price.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
            if (isAdmin)
              DataCell(
                Text(
                  'PKR ${pkg.profit.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: pkg.profit > 0
                        ? AppTheme.successColor
                        : (pkg.profit < 0 ? AppTheme.errorColor : AppColors.charcoal),
                  ),
                ),
              ),
            DataCell(StatusBadge(status: pkg.isActive ? 'active' : 'inactive')),
            if (isAdmin)
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    color: Colors.orange,
                    tooltip: 'Edit',
                    onPressed: () => _showPackageFormSheet(ctx,
                        existing: pkg, isAdmin: isAdmin),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    color: AppTheme.errorColor,
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(ctx, pkg),
                  ),
                ],
              )),
          ],
        );
      }).toList(),
    );
  }

  // ── Mobile / tablet card grid ───────────────────────────────────────────────

  /// Lays packages out as a responsive card grid: 1 column on mobile,
  /// 2 columns on tablet. Uses [Wrap] rather than [GridView] so each card
  /// can size to its own content height (descriptions/actions vary in
  /// length) without risking overflow from a fixed aspect ratio.
  Widget _buildCardGrid(
      List<PackageEntity> packages, bool isAdmin, int columns) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final itemWidth = columns <= 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: packages
              .map((pkg) => SizedBox(
                    width: itemWidth,
                    child: _buildCard(pkg, isAdmin),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildCard(PackageEntity pkg, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.lightGray.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(pkg.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primaryColor)),
              ),
              StatusBadge(status: pkg.isActive ? 'active' : 'inactive'),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _connectionChip(pkg.connectionType),
              _speedChip(pkg.speedMbps),
              if (isAdmin) ...[
                _infoChip(Icons.shopping_bag_outlined,
                    'Buy: PKR ${pkg.costPrice.toStringAsFixed(0)}'),
                _infoChip(Icons.monetization_on,
                    'Sell: PKR ${pkg.price.toStringAsFixed(0)}/mo'),
                _infoChip(
                  Icons.account_balance_wallet_outlined,
                  'Profit: PKR ${pkg.profit.toStringAsFixed(0)}',
                  color: pkg.profit > 0
                      ? AppTheme.successColor
                      : (pkg.profit < 0 ? AppTheme.errorColor : null),
                ),
              ],
            ],
          ),
          if (pkg.description != null && pkg.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              pkg.description!,
              style: const TextStyle(fontSize: 11, color: AppTheme.mediumGray),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (isAdmin) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  onPressed: () =>
                      _showPackageFormSheet(context, existing: pkg, isAdmin: isAdmin),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete', style: TextStyle(fontSize: 12)),
                  style:
                      TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                  onPressed: () => _confirmDelete(context, pkg),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Chip helpers ───────────────────────────────────────────────────────────

  Widget _connectionChip(ConnectionType type) {
    final isWireless = type == ConnectionType.wireless;
    final color = isWireless ? Colors.teal : AppColors.primaryBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isWireless ? Icons.wifi : Icons.cable, size: 11, color: color),
          const SizedBox(width: 4),
          Text(type.label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _speedChip(int mbps) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$mbps Mbps',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue)),
    );
  }

  Widget _infoChip(IconData icon, String label, {Color? color}) {
    final effectiveColor = color ?? AppTheme.mediumGray;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: effectiveColor),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: effectiveColor,
                fontWeight: color != null ? FontWeight.w600 : null)),
      ],
    );
  }

  // ── Error widget ───────────────────────────────────────────────────────────

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error, color: AppTheme.errorColor, size: 40),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _reload, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  // ── Delete confirmation ────────────────────────────────────────────────────

  Future<void> _confirmDelete(BuildContext ctx, PackageEntity pkg) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete Package'),
        content: Text(
            'Are you sure you want to delete "${pkg.name}"?\nThis action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) {
      ctx.read<PackagesBloc>().add(DeletePackageRequested(pkg.id));
    }
  }

  // ── Form side-sheet (Add / Edit) ───────────────────────────────────────────

  void _showPackageFormSheet(
    BuildContext context, {
    PackageEntity? existing,
    required bool isAdmin,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<PackagesBloc>(),
        child: PackageFormSheet(
          existing: existing,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Package Form Sheet
// ══════════════════════════════════════════════════════════════════════════════

class PackageFormSheet extends StatefulWidget {
  final PackageEntity? existing;

  const PackageFormSheet({super.key, this.existing});

  @override
  State<PackageFormSheet> createState() => _PackageFormSheetState();
}

class _PackageFormSheetState extends State<PackageFormSheet> {
  static const List<String> _commonSpeedSuggestions = [
    '5 Mbps',
    '10 Mbps',
    '15 Mbps',
    '20 Mbps',
    '25 Mbps',
    '30 Mbps',
    '40 Mbps',
    '50 Mbps',
    '75 Mbps',
    '100 Mbps',
    '150 Mbps',
    '200 Mbps',
    '300 Mbps',
    '500 Mbps',
    '1000 Mbps',
  ];

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  final FocusNode _nameFocusNode = FocusNode();
  late final TextEditingController _speedCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _costPriceCtrl;
  late final TextEditingController _descCtrl;

  late ConnectionType _connectionType;
  late bool _isActive;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _speedCtrl =
        TextEditingController(text: e != null ? e.speedMbps.toString() : '');
    _priceCtrl =
        TextEditingController(text: e != null ? e.price.toString() : '');
    _costPriceCtrl =
        TextEditingController(text: e != null ? e.costPrice.toString() : '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _connectionType = e?.connectionType ?? ConnectionType.wireless;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocusNode.dispose();
    _speedCtrl.dispose();
    _priceCtrl.dispose();
    _costPriceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final package = PackageEntity(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      speedMbps: int.parse(_speedCtrl.text.trim()),
      price: double.parse(_priceCtrl.text.trim()),
      costPrice: double.parse(_costPriceCtrl.text.trim()),
      connectionType: _connectionType,
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      isActive: _isActive,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    if (_isEdit) {
      context.read<PackagesBloc>().add(UpdatePackageRequested(package));
    } else {
      context.read<PackagesBloc>().add(AddPackageRequested(package));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // This sheet is a top-level modal spanning the full window, so the
    // MediaQuery-based Responsive helpers (not ResponsiveBuilder) are the
    // correct choice here.
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = Responsive.isMobile(context);
    // Desktop behaves like a right-side drawer of fixed width; mobile/tablet
    // get a full-width sheet.
    final sheetWidth =
        Responsive.isDesktop(context) ? 480.0 : screenWidth;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: sheetWidth,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(-4, 0)),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isEdit ? Icons.edit : Icons.add_circle_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEdit ? 'Edit Package' : 'Add New Package',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Form body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Package Name — autocomplete over common speed
                        // presets and names already used, so packages stay
                        // consistently named instead of drifting (e.g.
                        // "15mb" vs "15 Mbps"). Still freely editable.
                        Builder(builder: (context) {
                          final existingNames = <String>{};
                          final blocState =
                              context.read<PackagesBloc>().state;
                          if (blocState is PackagesLoaded) {
                            for (final p in blocState.packages) {
                              if (!_isEdit || p.id != widget.existing!.id) {
                                existingNames.add(p.name);
                              }
                            }
                          }
                          final suggestions = <String>{
                            ...existingNames,
                            ..._commonSpeedSuggestions,
                          }.toList()
                            ..sort();

                          return Autocomplete<String>(
                            textEditingController: _nameCtrl,
                            focusNode: _nameFocusNode,
                            optionsBuilder: (TextEditingValue value) {
                              final query = value.text.trim().toLowerCase();
                              if (query.isEmpty) return suggestions;
                              return suggestions.where(
                                  (s) => s.toLowerCase().contains(query));
                            },
                            onSelected: (selection) {
                              _nameCtrl.text = selection;
                              final match =
                                  RegExp(r'(\d+)').firstMatch(selection);
                              if (match != null &&
                                  _speedCtrl.text.trim().isEmpty) {
                                setState(
                                    () => _speedCtrl.text = match.group(1)!);
                              }
                            },
                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmit) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Package Name *',
                                  hintText: 'e.g. 20 Mbps Home',
                                  prefixIcon: Icon(Icons.wifi),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Name is required'
                                        : null,
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 16),

                        // Connection Type
                        DropdownButtonFormField<ConnectionType>(
                          value: _connectionType,
                          decoration: const InputDecoration(
                            labelText: 'Connection Type *',
                            prefixIcon: Icon(Icons.cable),
                          ),
                          items: ConnectionType.values
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.label),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _connectionType = v);
                            }
                          },
                          validator: (_) => null,
                        ),
                        const SizedBox(height: 16),

                        // Speed field
                        TextFormField(
                          controller: _speedCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: AppInputFormatters.integer,
                          decoration: const InputDecoration(
                            labelText: 'Speed (Mbps) *',
                            suffixText: 'Mbps',
                            prefixIcon: Icon(Icons.speed),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            final n = int.tryParse(v.trim());
                            if (n == null || n <= 0) {
                              return '> 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Buy price (cost) + Sell price (billed to customer):
                        // side by side on tablet/desktop, stacked on mobile.
                        Builder(builder: (context) {
                          final costPriceField = TextFormField(
                            controller: _costPriceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: AppInputFormatters.decimal,
                            decoration: const InputDecoration(
                              labelText: 'Buy Price (PKR) *',
                              helperText: 'What we pay upstream for this package',
                              prefixText: 'PKR ',
                              prefixIcon: Icon(Icons.shopping_bag_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              final n = double.tryParse(v.trim());
                              if (n == null || n < 0) {
                                return '>= 0';
                              }
                              return null;
                            },
                          );
                          final priceField = TextFormField(
                            controller: _priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: AppInputFormatters.decimal,
                            decoration: const InputDecoration(
                              labelText: 'Sell Price (PKR) *',
                              helperText: 'What the customer is billed',
                              prefixText: 'PKR ',
                              prefixIcon: Icon(Icons.monetization_on),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              final n = double.tryParse(v.trim());
                              if (n == null || n <= 0) {
                                return '> 0';
                              }
                              return null;
                            },
                          );

                          if (isMobile) {
                            return Column(
                              children: [
                                costPriceField,
                                const SizedBox(height: 16),
                                priceField,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: costPriceField),
                              const SizedBox(width: 12),
                              Expanded(child: priceField),
                            ],
                          );
                        }),
                        const SizedBox(height: 16),

                        // Description (optional)
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'e.g. Unlimited internet, no FUP',
                            prefixIcon: Icon(Icons.notes),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Is Active switch
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.toggle_on_outlined,
                                  color: AppColors.primaryBlue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Active',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                      _isActive
                                          ? 'Package is visible & assignable'
                                          : 'Package is hidden from customers',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isActive,
                                onChanged: (v) =>
                                    setState(() => _isActive = v),
                                activeColor: AppColors.primaryBlue,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action buttons: full-width stacked on mobile,
                        // inline row on tablet/desktop.
                        Builder(builder: (context) {
                          final cancelButton = OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          );
                          final saveButton = ElevatedButton.icon(
                            onPressed: _isSaving ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _isEdit ? Icons.save : Icons.check,
                                    size: 16),
                            label: Text(
                              _isSaving
                                  ? 'Saving...'
                                  : (_isEdit
                                      ? 'Save Changes'
                                      : 'Add Package'),
                            ),
                          );

                          if (isMobile) {
                            return Column(
                              children: [
                                SizedBox(
                                    width: double.infinity,
                                    child: saveButton),
                                const SizedBox(height: 12),
                                SizedBox(
                                    width: double.infinity,
                                    child: cancelButton),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: cancelButton),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: saveButton),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
