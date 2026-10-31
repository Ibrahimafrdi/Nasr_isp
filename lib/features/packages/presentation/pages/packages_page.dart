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

// ════════════════════════════════════════════════════════════════════════════
// HOW TO USE THIS FILE
// In lib/features/packages/presentation/pages/packages_page.dart:
//   1. Keep the imports at the top as they are.
//   2. Delete everything from `class PackagesPage` down to (but NOT including)
//      the banner comment "Package Form Sheet" (the line of ═══ just above
//      `class PackageFormSheet`).
//   3. Paste everything below this comment block in its place.
// The Add/Edit form (PackageFormSheet) is not touched.
// ════════════════════════════════════════════════════════════════════════════

const _kAccent = Color(0xFF0F766E);
const _kInk = Color(0xFF14213D);
const _kMuted = Color(0xFF5B6472);
const _kBorder = Color(0xFFE3E6EB);
const _kLine = Color(0xFFC9CED6);

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
      LoadPackages(
        filterByType: _filterType,
        activeOnly: _activeOnly ? true : null,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// Rs 3,000 style.
  String _rs(num amount) {
    final digits = amount.round().toString();
    final withCommas = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return 'Rs $withCommas';
  }

  int _marginPct(PackageEntity p) =>
      p.price > 0 ? (p.profit / p.price * 100).round() : 0;

  /// Smallest speed first; at the same speed, wireless before fibre.
  List<PackageEntity> _sorted(List<PackageEntity> packages) {
    final list = [...packages];
    list.sort((a, b) {
      final bySpeed = a.speedMbps.compareTo(b.speedMbps);
      if (bySpeed != 0) return bySpeed;
      return a.connectionType.index.compareTo(b.connectionType.index);
    });
    return list;
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
            final loaded = state is PackagesLoaded ? state : null;
            final packages = _sorted(loaded?.packages ?? <PackageEntity>[]);

            return SingleChildScrollView(
              padding: Responsive.pagePaddingFor(
                Responsive.deviceTypeOf(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Packages',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: _kInk,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'What you sell, what you pay, and what you earn.',
                              style: TextStyle(fontSize: 14, color: _kMuted),
                            ),
                          ],
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showPackageFormSheet(context, isAdmin: isAdmin),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add package'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            backgroundColor: _kAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Summary + warning (admin only: they use cost prices) ─
                  if (isAdmin && packages.isNotEmpty) ...[
                    _buildSummary(packages),
                    ..._buildLossWarning(packages),
                    const SizedBox(height: 24),
                  ],

                  // ── Filters ────────────────────────────────────────────
                  _buildFilterBar(),
                  const SizedBox(height: 16),

                  // ── Content ────────────────────────────────────────────
                  if (state is PackagesLoading)
                    const LoadingWidget(message: 'Loading packages...')
                  else if (state is PackagesError)
                    _buildError(state.message)
                  else if (loaded != null)
                    packages.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.wifi_off,
                            title: 'No Packages Found',
                            subtitle: 'Add a new package to begin.',
                          )
                        : ResponsiveSwitcher(
                            mobile: _buildCardGrid(packages, isAdmin, 1),
                            tablet: _buildCardGrid(packages, isAdmin, 2),
                            desktop: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _kBorder),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _buildTable(packages, isAdmin, context),
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

  // ── Summary cards ──────────────────────────────────────────────────────────

  Widget _statCard(String label, String value, {String? note, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _kMuted)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color ?? _kInk,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note, style: const TextStyle(fontSize: 12, color: _kMuted)),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary(List<PackageEntity> packages) {
    final byMargin = [...packages]
      ..sort((a, b) => _marginPct(b).compareTo(_marginPct(a)));
    final best = byMargin.first;
    final worst = byMargin.last;
    final avg =
        (packages.map(_marginPct).reduce((a, b) => a + b) / packages.length)
            .round();
    final activeCount = packages.where((p) => p.isActive).length;

    final cards = <Widget>[
      _statCard(
        'Packages shown',
        '${packages.length}',
        note: '$activeCount active',
      ),
      _statCard(
        'Average margin',
        '$avg%',
        note: 'Profit as a share of the sell price',
        color: _kAccent,
      ),
      _statCard('Best margin', '${_marginPct(best)}%', note: best.name),
      _statCard(
        'Lowest margin',
        '${_marginPct(worst)}%',
        note: worst.name,
        color: worst.profit <= 0 ? AppTheme.errorColor : null,
      ),
    ];

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

  /// A package sold at or below its buy price loses money on every customer.
  List<Widget> _buildLossWarning(List<PackageEntity> packages) {
    final losing = packages.where((p) => p.profit <= 0).toList();
    if (losing.isEmpty) return const [];
    const brown = Color(0xFF7A3E00);
    final names = losing.take(3).map((p) => p.name).join(', ');
    final extra = losing.length > 3 ? ' and ${losing.length - 3} more' : '';
    return [
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF2C98A)),
        ),
        child: Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 14, color: brown),
            children: [
              const TextSpan(
                text: 'Check these prices: ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: '$names$extra sell at or below what you pay for them.',
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // ── Filters (one row of pills) ─────────────────────────────────────────────

  Widget _pill(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? _kAccent : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? _kAccent : _kLine),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : _kInk,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _pill('All types', _filterType == null, () {
          setState(() => _filterType = null);
          _reload();
        }),
        for (final t in ConnectionType.values)
          _pill(t.label, _filterType == t, () {
            setState(() => _filterType = t);
            _reload();
          }),
        const SizedBox(width: 12),
        _pill('Active only', _activeOnly, () {
          setState(() => _activeOnly = !_activeOnly);
          _reload();
        }),
        if (_filterType != null || _activeOnly)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _kAccent,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () {
              setState(() {
                _filterType = null;
                _activeOnly = false;
              });
              _reload();
            },
            child: const Text('Clear filters'),
          ),
      ],
    );
  }

  // ── Desktop table (fills the full width) ───────────────────────────────────

  Widget _tableRow(List<int> flex, List<Widget> cells, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              flex: flex[i],
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
      color: _kMuted,
    ),
  );

  Widget _typePill(ConnectionType type) {
    final wireless = type == ConnectionType.wireless;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: wireless ? const Color(0xFFE8F0FE) : const Color(0xFFF1E8FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          type.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: wireless ? const Color(0xFF1A56B0) : const Color(0xFF6B2FA0),
          ),
        ),
      ),
    );
  }

  Color _profitColor(PackageEntity p) => p.profit > 0
      ? AppTheme.successColor
      : (p.profit < 0 ? AppTheme.errorColor : _kInk);

  Widget _buildTable(
    List<PackageEntity> packages,
    bool isAdmin,
    BuildContext ctx,
  ) {
    final flex = isAdmin
        ? const [22, 13, 9, 12, 13, 17, 10, 16]
        : const [34, 24, 18, 24];
    final minWidth = isAdmin ? 960.0 : 560.0;

    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth < minWidth ? minWidth : c.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                _tableRow(flex, [
                  _headerCell('Package'),
                  _headerCell('Type'),
                  _headerCell('Speed'),
                  if (isAdmin) _headerCell('Buy price'),
                  if (isAdmin) _headerCell('Sell price / month'),
                  if (isAdmin) _headerCell('Profit / month'),
                  _headerCell('Status'),
                  if (isAdmin) _headerCell('Actions'),
                ]),
                for (var i = 0; i < packages.length; i++)
                  _packageRow(
                    flex,
                    packages[i],
                    isAdmin,
                    ctx,
                    last: i == packages.length - 1,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _packageRow(
    List<int> flex,
    PackageEntity pkg,
    bool isAdmin,
    BuildContext ctx, {
    required bool last,
  }) {
    return _tableRow(flex, [
      Text(
        pkg.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: _kInk,
        ),
      ),
      _typePill(pkg.connectionType),
      Text(
        '${pkg.speedMbps} Mbps',
        style: const TextStyle(fontSize: 14, color: _kInk),
      ),
      if (isAdmin)
        Text(_rs(pkg.costPrice), style: const TextStyle(fontSize: 14)),
      if (isAdmin)
        Text(
          _rs(pkg.price),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      if (isAdmin)
        Text(
          '${_rs(pkg.profit)} (${_marginPct(pkg)}%)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _profitColor(pkg),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: StatusBadge(status: pkg.isActive ? 'active' : 'inactive'),
      ),
      if (isAdmin)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                foregroundColor: _kInk,
                side: const BorderSide(color: _kLine),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              onPressed: () =>
                  _showPackageFormSheet(ctx, existing: pkg, isAdmin: isAdmin),
              child: const Text('Edit'),
            ),
            PopupMenuButton<String>(
              tooltip: 'More actions',
              icon: const Icon(Icons.more_horiz),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onSelected: (v) {
                if (v == 'delete') _confirmDelete(ctx, pkg);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete package',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
          ],
        ),
    ], last: last);
  }

  // ── Mobile / tablet card grid ──────────────────────────────────────────────

  /// 1 column on mobile, 2 on tablet. Uses [Wrap] so each card sizes to its
  /// own content (no fixed aspect ratio, no overflow).
  Widget _buildCardGrid(
    List<PackageEntity> packages,
    bool isAdmin,
    int columns,
  ) {
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
              .map(
                (pkg) =>
                    SizedBox(width: itemWidth, child: _buildCard(pkg, isAdmin)),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildCard(PackageEntity pkg, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pkg.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: _kInk,
                  ),
                ),
              ),
              StatusBadge(status: pkg.isActive ? 'active' : 'inactive'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _typePill(pkg.connectionType),
              const SizedBox(width: 10),
              Text(
                '${pkg.speedMbps} Mbps',
                style: const TextStyle(fontSize: 13, color: _kMuted),
              ),
            ],
          ),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            _cardLine('Buy price', _rs(pkg.costPrice)),
            _cardLine('Sell price / month', _rs(pkg.price)),
            _cardLine(
              'Profit / month',
              '${_rs(pkg.profit)} (${_marginPct(pkg)}%)',
              color: _profitColor(pkg),
              bold: true,
            ),
          ],
          if (pkg.description != null && pkg.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              pkg.description!,
              style: const TextStyle(fontSize: 12, color: _kMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
                    foregroundColor: _kInk,
                    side: const BorderSide(color: _kLine),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _showPackageFormSheet(
                    context,
                    existing: pkg,
                    isAdmin: isAdmin,
                  ),
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
                    if (v == 'delete') _confirmDelete(context, pkg);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete package',
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

  Widget _cardLine(
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
          Text(label, style: const TextStyle(fontSize: 13, color: _kMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? _kInk,
            ),
          ),
        ],
      ),
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
          'Are you sure you want to delete "${pkg.name}"?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
        child: PackageFormSheet(existing: existing),
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
    _speedCtrl = TextEditingController(
      text: e != null ? e.speedMbps.toString() : '',
    );
    _priceCtrl = TextEditingController(
      text: e != null ? e.price.toString() : '',
    );
    _costPriceCtrl = TextEditingController(
      text: e != null ? e.costPrice.toString() : '',
    );
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
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
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
    final sheetWidth = Responsive.isDesktop(context) ? 480.0 : screenWidth;

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
                offset: Offset(-4, 0),
              ),
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
                    left: Radius.circular(20),
                  ),
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
                          fontWeight: FontWeight.bold,
                        ),
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
                        Builder(
                          builder: (context) {
                            final existingNames = <String>{};
                            final blocState = context
                                .read<PackagesBloc>()
                                .state;
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
                            }.toList()..sort();

                            return Autocomplete<String>(
                              textEditingController: _nameCtrl,
                              focusNode: _nameFocusNode,
                              optionsBuilder: (TextEditingValue value) {
                                final query = value.text.trim().toLowerCase();
                                if (query.isEmpty) return suggestions;
                                return suggestions.where(
                                  (s) => s.toLowerCase().contains(query),
                                );
                              },
                              onSelected: (selection) {
                                _nameCtrl.text = selection;
                                final match = RegExp(
                                  r'(\d+)',
                                ).firstMatch(selection);
                                if (match != null &&
                                    _speedCtrl.text.trim().isEmpty) {
                                  setState(
                                    () => _speedCtrl.text = match.group(1)!,
                                  );
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
                          },
                        ),
                        const SizedBox(height: 16),

                        // Connection Type
                        DropdownButtonFormField<ConnectionType>(
                          value: _connectionType,
                          decoration: const InputDecoration(
                            labelText: 'Connection Type *',
                            prefixIcon: Icon(Icons.cable),
                          ),
                          items: ConnectionType.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.label),
                                ),
                              )
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
                        Builder(
                          builder: (context) {
                            final costPriceField = TextFormField(
                              controller: _costPriceCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: AppInputFormatters.decimal,
                              decoration: const InputDecoration(
                                labelText: 'Buy Price (PKR) *',
                                helperText:
                                    'What we pay upstream for this package',
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
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
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
                          },
                        ),
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
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.toggle_on_outlined,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Active',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _isActive
                                          ? 'Package is visible & assignable'
                                          : 'Package is hidden from customers',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isActive,
                                onChanged: (v) => setState(() => _isActive = v),
                                activeColor: AppColors.primaryBlue,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action buttons: full-width stacked on mobile,
                        // inline row on tablet/desktop.
                        Builder(
                          builder: (context) {
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
                                      size: 16,
                                    ),
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
                                    child: saveButton,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: cancelButton,
                                  ),
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
                          },
                        ),
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
