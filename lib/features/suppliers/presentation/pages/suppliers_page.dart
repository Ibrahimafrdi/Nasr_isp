import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:nasr_isp/features/suppliers/presentation/bloc/supplier_bloc.dart';
import 'package:nasr_isp/features/suppliers/presentation/bloc/supplier_event.dart';
import 'package:nasr_isp/features/suppliers/presentation/bloc/supplier_state.dart';
import 'package:nasr_isp/features/suppliers/presentation/widgets/add_edit_supplier_dialog.dart';
import 'package:nasr_isp/features/suppliers/presentation/widgets/supplier_card.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _onlyPending = false;

  @override
  void initState() {
    super.initState();
    context.read<SupplierBloc>().add(const LoadSuppliersEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: compact ? 16 : 20,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: compact ? 16 : 20),
          ),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Shrinks the number a little instead of cutting it off.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4 cards in one row on wide screens, 2 x 2 on phones.
  Widget _buildStatGrid(List<Widget Function(bool compact)> builders) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 12.0;
        final cols = c.maxWidth >= 800 ? 4 : 2;
        final compact = cols == 2;
        final width = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: builders
              .map((b) => SizedBox(width: width, child: b(compact)))
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'en_US');
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppTheme.veryLightGray,
      body: BlocConsumer<SupplierBloc, SupplierState>(
        listener: (context, state) {
          if (state is SupplierActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.successColor,
              ),
            );
          } else if (state is SupplierError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          List<SupplierEntity> allSuppliers = [];
          if (state is SuppliersLoaded) {
            allSuppliers = state.suppliers;
          }

          // Filter by search query and pending balance
          final filteredSuppliers = allSuppliers.where((s) {
            final matchesSearch =
                _searchQuery.isEmpty ||
                s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.phone.contains(_searchQuery);
            final matchesPending = !_onlyPending || s.pendingBalance > 0.0001;
            return matchesSearch && matchesPending;
          }).toList();

          // Financial aggregates
          final double totalPurchased = allSuppliers.fold(
            0.0,
            (sum, s) => sum + s.totalPurchased,
          );
          final double totalPaid = allSuppliers.fold(
            0.0,
            (sum, s) => sum + s.totalPaid,
          );
          final double totalPending = allSuppliers.fold(
            0.0,
            (sum, s) => sum + s.pendingBalance,
          );

          final addButton = ElevatedButton.icon(
            onPressed: () async {
              final newId = await AddEditSupplierDialog.show(context);
              if (newId != null && context.mounted) {
                context.read<SupplierBloc>().add(const LoadSuppliersEvent());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Supplier'),
          );

          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Suppliers & Procurement',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage equipment suppliers, purchase invoices, and payments',
                style: TextStyle(fontSize: 13, color: AppTheme.mediumGray),
              ),
            ],
          );

          return SingleChildScrollView(
            padding: Responsive.pagePaddingFor(
              Responsive.deviceTypeOf(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: side by side on wide screens, stacked on phones
                LayoutBuilder(
                  builder: (context, c) {
                    if (c.maxWidth >= 600) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: titleBlock),
                          const SizedBox(width: 16),
                          addButton,
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleBlock,
                        const SizedBox(height: 12),
                        addButton,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // KPI Stat Cards
                _buildStatGrid([
                  (compact) => _buildStatCard(
                    title: 'Total Suppliers',
                    value: '${allSuppliers.length}',
                    icon: Icons.store,
                    color: AppColors.primaryBlue,
                    compact: compact,
                  ),
                  (compact) => _buildStatCard(
                    title: 'Total Purchased',
                    value: 'Rs. ${currencyFormat.format(totalPurchased)}',
                    icon: Icons.shopping_bag_outlined,
                    color: AppColors.charcoal,
                    compact: compact,
                  ),
                  (compact) => _buildStatCard(
                    title: 'Total Paid',
                    value: 'Rs. ${currencyFormat.format(totalPaid)}',
                    icon: Icons.check_circle_outline,
                    color: AppTheme.successColor,
                    compact: compact,
                  ),
                  (compact) => _buildStatCard(
                    title: 'Outstanding Dues',
                    value: 'Rs. ${currencyFormat.format(totalPending)}',
                    icon: Icons.pending_actions,
                    color: totalPending > 0
                        ? AppTheme.errorColor
                        : AppTheme.successColor,
                    compact: compact,
                  ),
                ]),
                const SizedBox(height: 20),

                // Search & Filters Panel
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGray),
                  ),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final searchField = TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name or phone...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.lightGray),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      );

                      final pendingChip = FilterChip(
                        label: const Text('Pending Balance Only'),
                        selected: _onlyPending,
                        onSelected: (val) => setState(() => _onlyPending = val),
                        selectedColor: AppTheme.errorColor.withValues(
                          alpha: 0.15,
                        ),
                        checkmarkColor: AppTheme.errorColor,
                        labelStyle: TextStyle(
                          color: _onlyPending
                              ? AppTheme.errorColor
                              : AppTheme.darkGray,
                          fontWeight: _onlyPending
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      );

                      // Phones: search on top, chip underneath
                      if (c.maxWidth < 600) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            searchField,
                            const SizedBox(height: 10),
                            pendingChip,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: searchField),
                          const SizedBox(width: 12),
                          pendingChip,
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Content
                if (state is SupplierLoading && allSuppliers.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (filteredSuppliers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightGray),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: AppTheme.mediumGray.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No suppliers found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Add a supplier to record inventory purchases and payments.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Grid on desktop, List on mobile
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (isDesktop && constraints.maxWidth > 700) {
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: filteredSuppliers.map((supplier) {
                            final cardWidth = (constraints.maxWidth - 16) / 2;
                            return SizedBox(
                              width: cardWidth,
                              child: SupplierCard(
                                supplier: supplier,
                                onTap: () => context.go(
                                  '${RoutePaths.suppliers}/${supplier.id}',
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      } else {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredSuppliers.length,
                          itemBuilder: (context, index) {
                            final supplier = filteredSuppliers[index];
                            return SupplierCard(
                              supplier: supplier,
                              onTap: () => context.go(
                                '${RoutePaths.suppliers}/${supplier.id}',
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
