import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:nasr_isp/features/payments/presentation/widgets/payment_card_list.dart';
import 'package:nasr_isp/features/payments/presentation/widgets/payment_details_dialog.dart';
import 'package:nasr_isp/features/payments/presentation/widgets/payment_filter_panel.dart';
import 'package:nasr_isp/features/payments/presentation/widgets/payment_stats_cards.dart';
import 'package:nasr_isp/features/payments/presentation/widgets/payment_table.dart';
import 'package:nasr_isp/features/payments/presentation/widgets/settle_payment_dialog.dart';
import 'package:nasr_isp/shared/models/models.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  String? _statusFilter;
  String? _methodFilter;
  DateTime? _dateRangeStart;
  DateTime? _dateRangeEnd;

  int get _activeFilterCount {
    int count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_statusFilter != null) count++;
    if (_methodFilter != null) count++;
    if (_dateRangeStart != null) count++;
    if (_dateRangeEnd != null) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _triggerLoad();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _triggerLoad({int page = 1}) {
    context.read<PaymentsBloc>().add(
      LoadPaymentsEvent(
        page: page,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        filterStatuses: _statusFilter != null ? [_statusFilter!] : null,
        dateRangeStart: _dateRangeStart,
        dateRangeEnd: _dateRangeEnd,
      ),
    );
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _statusFilter = null;
      _methodFilter = null;
      _dateRangeStart = null;
      _dateRangeEnd = null;
    });
    _triggerLoad(page: 1);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRangeStart != null && _dateRangeEnd != null
          ? DateTimeRange(start: _dateRangeStart!, end: _dateRangeEnd!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.navyDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || picked == null) return;

    setState(() {
      _dateRangeStart = picked.start;
      _dateRangeEnd = picked.end;
    });
    _triggerLoad(page: 1);
  }

  void _onSearchChanged(String val) {
    setState(() => _searchQuery = val);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _triggerLoad(page: 1);
    });
  }

  void _onStatusFilterChanged(String? val) {
    setState(() => _statusFilter = val);
    _triggerLoad(page: 1);
  }

  void _onMethodFilterChanged(String? val) {
    setState(() => _methodFilter = val);
  }

  Future<void> _onSettlePaymentRequested(PaymentModel payment) async {
    await showSettlePaymentDialog(
      context: context,
      payment: payment,
      onConfirm: ({
        required double receivedAmount,
        required String method,
        required String? notes,
      }) async {
        final newPaid = payment.paidAmount + receivedAmount;
        final isPaidInFull = newPaid >= payment.amount;
        final stillOwed = (payment.amount - newPaid).clamp(0.0, double.infinity);

        context.read<PaymentsBloc>().add(
          UpdatePaymentEvent(
            payment.copyWith(
              paidAmount: newPaid,
              status: PaymentEntity.statusFor(
                amount: payment.amount,
                paidAmount: newPaid,
              ),
              completedDate: isPaidInFull ? DateTime.now() : null,
              method: method,
              notes: notes,
            ),
          ),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isPaidInFull
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    isPaidInFull
                        ? '${DateTimeUtils.formatCurrency(receivedAmount)} collected — ${payment.customerName} settled in full.'
                        : '${DateTimeUtils.formatCurrency(receivedAmount)} collected — ${DateTimeUtils.formatCurrency(stillOwed)} remaining.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor:
                isPaidInFull ? AppColors.successGreen : AppColors.warningOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }

  void _onViewReceiptRequested(PaymentModel payment, bool isAdmin) {
    showPaymentDetailsDialog(
      context: context,
      payment: payment,
      isAdmin: isAdmin,
      onSettle: isAdmin && payment.status != 'paid'
          ? (p) => _onSettlePaymentRequested(p)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = Responsive.deviceTypeOf(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: Text('Not authenticated')),
          );
        }
        final isAdmin = authState.user.role == 'admin';

        return BlocBuilder<PaymentsBloc, PaymentsState>(
          builder: (context, state) {
            return ColoredBox(
              color: const Color(0xFFF8FAFC),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: Responsive.pagePaddingFor(deviceType),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, state),
                    const SizedBox(height: AppSpacing.lg),

                    // Top Financial KPI Summary Cards (Admin Only)
                    if (state is PaymentsLoaded && isAdmin) ...[
                      PaymentStatsCards(
                        totalAmount: state.totalAmount,
                        collectedAmount: state.collectedAmount,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Filter Panel
                    PaymentFilterPanel(
                      searchController: _searchController,
                      selectedStatus: _statusFilter,
                      selectedMethod: _methodFilter,
                      activeFilterCount: _activeFilterCount,
                      hasDateRange:
                          _dateRangeStart != null && _dateRangeEnd != null,
                      dateRangeLabel:
                          (_dateRangeStart != null && _dateRangeEnd != null)
                              ? '${DateTimeUtils.formatDate(_dateRangeStart!)} – ${DateTimeUtils.formatDate(_dateRangeEnd!)}'
                              : null,
                      onSearchChanged: _onSearchChanged,
                      onStatusChanged: _onStatusFilterChanged,
                      onMethodChanged: _onMethodFilterChanged,
                      onPickDateRange: _pickDateRange,
                      onClearDateRange: () {
                        setState(() {
                          _dateRangeStart = null;
                          _dateRangeEnd = null;
                        });
                        _triggerLoad(page: 1);
                      },
                      onClearFilters: _clearFilters,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Main Content Table / Card List
                    if (state is PaymentsLoaded) ...[
                      _buildPaymentsContent(state, isAdmin),
                    ] else if (state is PaymentsLoading) ...[
                      _buildLoadingSkeleton(),
                    ] else if (state is PaymentsError) ...[
                      _buildErrorState(state.message),
                    ] else ...[
                      _buildEmptyState(),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, PaymentsState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payments & Billing Ledger',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Monitor subscription billings, track collections, and settle customer arrears.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.darkGray,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Refresh Button
            IconButton(
              tooltip: 'Refresh ledger',
              onPressed: () => _triggerLoad(page: 1),
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.charcoal,
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.lightGray),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentsContent(PaymentsLoaded state, bool isAdmin) {
    // Apply client-side method filter if chosen
    var filteredPayments = state.payments;
    if (_methodFilter != null && _methodFilter!.isNotEmpty) {
      filteredPayments = filteredPayments
          .where((p) => (p.method ?? '').toLowerCase() == _methodFilter!.toLowerCase())
          .toList();
    }

    if (filteredPayments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 28,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Payment Records Found',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _activeFilterCount > 0
                  ? 'No payment matches your current active filters. Try adjusting your search query or status filters.'
                  : 'No subscription billing records have been generated yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.mediumGray,
              ),
            ),
            if (_activeFilterCount > 0) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset All Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveSwitcher(
          mobile: PaymentCardList(
            payments: filteredPayments,
            isAdmin: isAdmin,
            onRecordPayment: _onSettlePaymentRequested,
            onViewReceipt: (p) => _onViewReceiptRequested(p, isAdmin),
          ),
          desktop: PaymentTable(
            payments: filteredPayments,
            isAdmin: isAdmin,
            onSettle: _onSettlePaymentRequested,
            onViewReceipt: (p) => _onViewReceiptRequested(p, isAdmin),
          ),
        ),
        if (state.totalPages > 1 || state.hasMore) ...[
          const SizedBox(height: AppSpacing.lg),
          PaginationBar(
            currentPage: state.currentPage,
            totalPages: state.totalPages,
            filterStatuses:
                _statusFilter != null ? [_statusFilter!] : null,
            onPageChanged: (page) => _triggerLoad(page: page),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Loading payments & general ledger...',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.errorRed,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load payments',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _triggerLoad(page: 1),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.receipt_long,
      title: 'No Data Available',
      subtitle: 'Unable to retrieve payment records at this time.',
    );
  }
}
