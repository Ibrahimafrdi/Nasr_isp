import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_payment_entity.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_purchase_entity.dart';
import 'package:nasr_isp/features/suppliers/presentation/bloc/supplier_bloc.dart';
import 'package:nasr_isp/features/suppliers/presentation/bloc/supplier_event.dart';
import 'package:nasr_isp/features/suppliers/presentation/bloc/supplier_state.dart';
import 'package:nasr_isp/features/suppliers/presentation/widgets/add_edit_supplier_dialog.dart';
import 'package:nasr_isp/features/suppliers/presentation/widgets/add_supplier_payment_dialog.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';

import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class SupplierDetailPage extends StatefulWidget {
  final String supplierId;

  const SupplierDetailPage({super.key, required this.supplierId});

  @override
  State<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends State<SupplierDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<SupplierBloc>().add(
      LoadSupplierDetailEvent(widget.supplierId),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRecordPayment(
    SupplierEntity supplier,
    List<SupplierPurchaseEntity> purchases, {
    SupplierPurchaseEntity? initialPurchase,
  }) async {
    final pendingPurchases = purchases
        .where((p) => !p.isCancelled && p.remainingAmount > 0.0001)
        .toList();

    final success = await AddSupplierPaymentDialog.show(
      context,
      supplierId: supplier.id,
      pendingPurchases: pendingPurchases,
      initialPurchase: initialPurchase,
    );

    if (success == true && mounted) {
      context.read<SupplierBloc>().add(
        LoadSupplierDetailEvent(widget.supplierId),
      );
    }
  }

  void _confirmCancelPurchase(SupplierPurchaseEntity purchase) {
    showDialog(
      context: context,
      builder: (dialogCtx) => ConfirmationDialog(
        title: 'Cancel Purchase',
        message:
            'Are you sure you want to cancel the purchase of ${purchase.quantity}x ${purchase.itemName} (Rs. ${NumberFormat('#,##0').format(purchase.totalAmount)})?\n\nThis will reverse the inventory stock and update the supplier balance.',
        confirmLabel: 'Cancel Purchase',
        isDestructive: true,
        onCancel: () => Navigator.pop(dialogCtx),
        onConfirm: () {
          context.read<SupplierBloc>().add(
            CancelPurchaseEvent(
              purchaseId: purchase.id,
              supplierId: widget.supplierId,
            ),
          );
        },
      ),
    );
  }

  void _confirmDeactivateSupplier(SupplierEntity supplier) {
    showDialog(
      context: context,
      builder: (dialogCtx) => ConfirmationDialog(
        title: 'Deactivate Supplier',
        message:
            'Are you sure you want to deactivate ${supplier.name}? It will be hidden from new purchase orders.',
        confirmLabel: 'Deactivate',
        isDestructive: true,
        onCancel: () => Navigator.pop(dialogCtx),
        onConfirm: () {
          context.read<SupplierBloc>().add(
            DeactivateSupplierEvent(supplier.id),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
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

  /// 3 cards in one row on wide screens, stacked on phones.
  Widget _buildStatGrid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 12.0;
        final cols = c.maxWidth >= 700 ? 3 : 1;
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

  /// Puts two pieces side by side, and lets the second drop to the next
  /// line on a small screen instead of overflowing.
  Widget _spread(Widget left, Widget right) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [left, right],
      ),
    );
  }

  Widget _buildHeader(
    SupplierEntity supplier,
    List<SupplierPurchaseEntity> purchases,
    List<SupplierPurchaseEntity> pendingPurchases,
  ) {
    final address = supplier.address;
    final phoneLine =
        'Phone: ${supplier.phone}${address != null && address.isNotEmpty ? ' · $address' : ''}';

    final titleBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.suppliers),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      supplier.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                      ),
                    ),
                    if (!supplier.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.mediumGray.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Inactive',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.darkGray,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  phoneLine,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final updatedId = await AddEditSupplierDialog.show(
              context,
              supplier: supplier,
            );
            if (updatedId != null && context.mounted) {
              context.read<SupplierBloc>().add(
                LoadSupplierDetailEvent(widget.supplierId),
              );
            }
          },
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Edit'),
        ),
        if (supplier.isActive)
          OutlinedButton.icon(
            onPressed: () => _confirmDeactivateSupplier(supplier),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: BorderSide(
                color: AppTheme.errorColor.withValues(alpha: 0.4),
              ),
            ),
            icon: const Icon(Icons.block, size: 16),
            label: const Text('Deactivate'),
          ),
        ElevatedButton.icon(
          onPressed: pendingPurchases.isEmpty
              ? null
              : () => _showRecordPayment(supplier, purchases),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.payment, size: 16),
          label: const Text('Record Payment'),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        // Wide screens: name on the left, buttons on the right.
        if (c.maxWidth >= 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 12),
              actions,
            ],
          );
        }
        // Phones: name first, buttons underneath.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [titleBlock, const SizedBox(height: 12), actions],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'en_US');

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
          if (state is SupplierLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is! SupplierDetailLoaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load supplier details'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<SupplierBloc>().add(
                      LoadSupplierDetailEvent(widget.supplierId),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final detail = state.detail;
          final supplier = detail.supplier;
          final purchases = detail.purchases;
          final payments = detail.payments;

          final hasPendingBalance = supplier.pendingBalance > 0.0001;
          final pendingPurchases = purchases
              .where((p) => !p.isCancelled && p.remainingAmount > 0.0001)
              .toList();

          return SingleChildScrollView(
            padding: Responsive.pagePaddingFor(
              Responsive.deviceTypeOf(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top navigation & actions
                _buildHeader(supplier, purchases, pendingPurchases),
                const SizedBox(height: 20),

                // Financial Summary Cards
                _buildStatGrid([
                  _buildStatCard(
                    title: 'Total Purchased',
                    value:
                        'Rs. ${currencyFormat.format(supplier.totalPurchased)}',
                    icon: Icons.receipt_long,
                    color: AppColors.charcoal,
                  ),
                  _buildStatCard(
                    title: 'Total Paid',
                    value: 'Rs. ${currencyFormat.format(supplier.totalPaid)}',
                    icon: Icons.check_circle_outline,
                    color: AppTheme.successColor,
                  ),
                  _buildStatCard(
                    title: 'Pending Balance',
                    value:
                        'Rs. ${currencyFormat.format(supplier.pendingBalance)}',
                    icon: Icons.pending_actions,
                    color: hasPendingBalance
                        ? AppTheme.errorColor
                        : AppTheme.successColor,
                  ),
                ]),
                const SizedBox(height: 24),

                // Tab Header
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGray),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: AppTheme.mediumGray,
                        indicatorColor: AppTheme.primaryColor,
                        tabs: [
                          Tab(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Purchases (${purchases.length})'),
                                ],
                              ),
                            ),
                          ),
                          Tab(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.payments_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Payments (${payments.length})'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Views
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: PURCHASES
                      _buildPurchasesTab(purchases, supplier, currencyFormat),

                      // TAB 2: PAYMENTS
                      _buildPaymentsTab(payments, currencyFormat),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPurchasesTab(
    List<SupplierPurchaseEntity> purchases,
    SupplierEntity supplier,
    NumberFormat currencyFormat,
  ) {
    if (purchases.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: AppTheme.mediumGray,
              ),
              SizedBox(height: 8),
              Text(
                'No purchases recorded',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Purchases are created automatically when adding or restocking inventory.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.mediumGray),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        final isCancelled = purchase.isCancelled;
        final dateStr = purchase.date != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(purchase.date!)
            : '—';

        Color statusColor;
        switch (purchase.status) {
          case SupplierPaymentStatus.paid:
            statusColor = AppTheme.successColor;
            break;
          case SupplierPaymentStatus.partial:
            statusColor = AppTheme.warningColor;
            break;
          case SupplierPaymentStatus.unpaid:
            statusColor = AppTheme.errorColor;
            break;
        }

        if (isCancelled) {
          statusColor = AppTheme.mediumGray;
        }

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColors.lightGray),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item name + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        isCancelled ? Icons.cancel_outlined : Icons.inventory,
                        size: 20,
                        color: isCancelled
                            ? AppTheme.mediumGray
                            : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        purchase.itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          decoration: isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCancelled
                              ? AppTheme.mediumGray
                              : AppColors.charcoal,
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
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isCancelled ? 'Cancelled' : purchase.status.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (purchase.invoiceNo != null &&
                    purchase.invoiceNo!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 28),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Inv: ${purchase.invoiceNo}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                _spread(
                  Text(
                    'Qty: ${purchase.quantity}  ·  Unit Cost: Rs. ${currencyFormat.format(purchase.unitCost)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.darkGray,
                    ),
                  ),
                  Text(
                    'Total: Rs. ${currencyFormat.format(purchase.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _spread(
                  Text(
                    'Paid: Rs. ${currencyFormat.format(purchase.paidAmount)}  ·  Due: Rs. ${currencyFormat.format(purchase.remainingAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: purchase.remainingAmount > 0
                          ? AppTheme.warningColor
                          : AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ),
                if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Notes: ${purchase.notes}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
                const Divider(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (!isCancelled && purchase.remainingAmount > 0.0001)
                        TextButton.icon(
                          onPressed: () => _showRecordPayment(
                            supplier,
                            purchases,
                            initialPurchase: purchase,
                          ),
                          icon: const Icon(Icons.payment, size: 16),
                          label: const Text('Pay Due'),
                        ),
                      if (purchase.canBeCancelled)
                        TextButton.icon(
                          onPressed: () => _confirmCancelPurchase(purchase),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                          ),
                          icon: const Icon(Icons.cancel, size: 16),
                          label: const Text('Cancel Purchase'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab(
    List<SupplierPaymentEntity> payments,
    NumberFormat currencyFormat,
  ) {
    if (payments.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.payment_outlined,
                size: 40,
                color: AppTheme.mediumGray,
              ),
              SizedBox(height: 8),
              Text(
                'No payments recorded yet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Payments recorded against purchases will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.mediumGray),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        final dateStr = payment.date != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(payment.date!)
            : '—';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColors.lightGray),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.successColor.withValues(
                    alpha: 0.12,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppTheme.successColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _spread(
                        Text(
                          'Rs. ${currencyFormat.format(payment.amount)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            payment.method.displayName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _spread(
                        Text(
                          'Linked Purchase: #${payment.purchaseId.length > 8 ? payment.purchaseId.substring(0, 8) : payment.purchaseId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ),
                      if (payment.notes != null &&
                          payment.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          payment.notes!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.darkGray,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
