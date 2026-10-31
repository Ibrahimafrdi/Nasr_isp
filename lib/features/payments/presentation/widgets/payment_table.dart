import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/payments/data/models/payment_model.dart';
import 'package:nasr_isp/shared/widgets/status_badge.dart';

// Column flex sizing
const int _fCustomer = 18;
const int _fBilled = 10;
const int _fCollected = 11;
const int _fOwed = 10;
const int _fCovers = 11;
const int _fStatus = 9;
const int _fMethod = 10;
const double _wAction = 140;

/// Enterprise-grade Desktop Data Table for Payments & General Ledger.
class PaymentTable extends StatelessWidget {
  final List<PaymentModel> payments;
  final bool isAdmin;
  final void Function(PaymentModel payment) onSettle;
  final void Function(PaymentModel payment)? onViewReceipt;

  const PaymentTable({
    super.key,
    required this.payments,
    required this.isAdmin,
    required this.onSettle,
    this.onViewReceipt,
  });

  static const double _minTableWidth = 1020;

  @override
  Widget build(BuildContext context) {
    final tableContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TableHeader(isAdmin: isAdmin),
        ...payments.map(
          (p) => _TableItemRow(
            payment: p,
            isAdmin: isAdmin,
            onSettle: onSettle,
            onViewReceipt: onViewReceipt,
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final Widget body = constraints.maxWidth >= _minTableWidth
            ? tableContent
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: _minTableWidth,
                  child: tableContent,
                ),
              );

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGray),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: body,
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  final bool isAdmin;
  const _TableHeader({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.darkGray,
      letterSpacing: 0.3,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: AppColors.lightGray)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: _fCustomer,
            child: Text('CUSTOMER & CYCLE', style: textStyle),
          ),
          if (isAdmin) ...[
            Expanded(flex: _fBilled, child: Text('BILLED', style: textStyle)),
            Expanded(
              flex: _fCollected,
              child: Text('COLLECTED', style: textStyle),
            ),
            Expanded(flex: _fOwed, child: Text('BALANCE DUE', style: textStyle)),
          ],
          Expanded(
            flex: _fCovers,
            child: Text('VALIDITY UNTIL', style: textStyle),
          ),
          Expanded(flex: _fStatus, child: Text('STATUS', style: textStyle)),
          Expanded(flex: _fMethod, child: Text('METHOD', style: textStyle)),
          SizedBox(
            width: _wAction,
            child: Text(
              'ACTIONS',
              style: textStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableItemRow extends StatefulWidget {
  final PaymentModel payment;
  final bool isAdmin;
  final void Function(PaymentModel payment) onSettle;
  final void Function(PaymentModel payment)? onViewReceipt;

  const _TableItemRow({
    required this.payment,
    required this.isAdmin,
    required this.onSettle,
    this.onViewReceipt,
  });

  @override
  State<_TableItemRow> createState() => _TableItemRowState();
}

class _TableItemRowState extends State<_TableItemRow> {
  bool _isHovered = false;

  String _methodLabel(String? method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'bankTransfer':
        return 'Bank Transfer';
      case 'easypaisa':
        return 'EasyPaisa';
      case 'jazzcash':
        return 'JazzCash';
      default:
        return method?.isNotEmpty == true ? method! : '—';
    }
  }

  IconData _methodIcon(String? method) {
    switch (method) {
      case 'cash':
        return Icons.payments_outlined;
      case 'bankTransfer':
        return Icons.account_balance_outlined;
      case 'easypaisa':
      case 'jazzcash':
        return Icons.phone_android_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final isPaid = p.status == 'paid';
    final hasBalance = p.remainingAmount > 0;
    final coversTo = p.periodEnd ?? p.dueDate;

    final double collectionProgress = p.amount > 0
        ? (p.paidAmount / p.amount).clamp(0.0, 1.0)
        : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onViewReceipt != null
            ? () => widget.onViewReceipt!(p)
            : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF8FAFC) : Colors.white,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFF1F5F9)),
            ),
          ),
          child: Row(
            children: [
              // Customer Avatar + Name & Cycle
              Expanded(
                flex: _fCustomer,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppColors.primaryBlue.withValues(alpha: 0.1),
                      child: Text(
                        p.customerName.isNotEmpty
                            ? p.customerName[0].toUpperCase()
                            : 'C',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (p.billingMonth != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    p.billingMonth!,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkGray,
                                    ),
                                  ),
                                ),
                              ] else
                                Text(
                                  'Standard Charge',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.mediumGray,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Billed Amount
              if (widget.isAdmin) ...[
                Expanded(
                  flex: _fBilled,
                  child: Text(
                    DateTimeUtils.formatCurrency(p.amount),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),

                // Collected Amount + Mini Progress Bar if partial
                Expanded(
                  flex: _fCollected,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateTimeUtils.formatCurrency(p.paidAmount),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.successGreen,
                        ),
                      ),
                      if (!isPaid && p.paidAmount > 0) ...[
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 80,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: collectionProgress,
                              minHeight: 4,
                              backgroundColor: AppColors.lightGray,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.successGreen,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Balance Due
                Expanded(
                  flex: _fOwed,
                  child: hasBalance
                      ? Text(
                          DateTimeUtils.formatCurrency(p.remainingAmount),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.errorRed,
                          ),
                        )
                      : Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: AppColors.successGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Settled',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.successGreen,
                              ),
                            ),
                          ],
                        ),
                ),
              ],

              // Validity / Covers To
              Expanded(
                flex: _fCovers,
                child: Text(
                  coversTo != null
                      ? DateTimeUtils.formatDate(coversTo)
                      : '—',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.charcoal,
                  ),
                ),
              ),

              // Status Badge
              Expanded(
                flex: _fStatus,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(status: p.status),
                ),
              ),

              // Payment Method
              Expanded(
                flex: _fMethod,
                child: Row(
                  children: [
                    Icon(
                      _methodIcon(p.method),
                      size: 15,
                      color: AppColors.darkGray,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _methodLabel(p.method),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              SizedBox(
                width: _wAction,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.onViewReceipt != null)
                      IconButton(
                        tooltip: 'View Receipt Details',
                        icon: const Icon(
                          Icons.receipt_long_rounded,
                          size: 18,
                          color: AppColors.darkGray,
                        ),
                        splashRadius: 18,
                        onPressed: () => widget.onViewReceipt!(p),
                      ),
                    if (widget.isAdmin && !isPaid)
                      ElevatedButton.icon(
                        onPressed: () => widget.onSettle(p),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.payments_rounded, size: 14),
                        label: Text(
                          'Settle',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
