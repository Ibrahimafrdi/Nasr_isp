import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/utils/utils.dart';

/// Redesigned enterprise KPI stats cards for the Payments page.
/// Displays 4 key financial metrics with progress indicators,
/// clean icons, and responsive desktop/tablet/mobile grid layout.
class PaymentStatsCards extends StatelessWidget {
  final double totalAmount;
  final double collectedAmount;

  const PaymentStatsCards({
    super.key,
    required this.totalAmount,
    required this.collectedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final owed = (totalAmount - collectedAmount).clamp(0.0, double.infinity);
    final percent = totalAmount > 0
        ? (collectedAmount / totalAmount).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final percentStr = (percent * 100).toStringAsFixed(1);

    final billedCard = _PaymentKpiCard(
      title: 'Total Invoiced',
      value: DateTimeUtils.formatCurrency(totalAmount),
      subtitle: 'Subscription charges in view',
      icon: Icons.request_quote_rounded,
      accentColor: AppColors.primaryBlue,
      bgColor: AppColors.primaryBlue.withValues(alpha: 0.08),
    );

    final collectedCard = _PaymentKpiCard(
      title: 'Total Collected',
      value: DateTimeUtils.formatCurrency(collectedAmount),
      subtitle: '$percentStr% of invoiced amount',
      icon: Icons.account_balance_wallet_rounded,
      accentColor: AppColors.successGreen,
      bgColor: AppColors.successGreen.withValues(alpha: 0.08),
      progress: percent,
    );

    final owedCard = _PaymentKpiCard(
      title: 'Outstanding Arrears',
      value: DateTimeUtils.formatCurrency(owed),
      subtitle: owed > 0 ? 'Remaining to be settled' : 'All invoices settled',
      icon: Icons.pending_actions_rounded,
      accentColor: owed > 0 ? AppColors.errorRed : AppColors.successGreen,
      bgColor: (owed > 0 ? AppColors.errorRed : AppColors.successGreen)
          .withValues(alpha: 0.08),
      badgeText: owed > 0 ? 'Due' : 'Clear',
      badgeColor: owed > 0 ? AppColors.errorRed : AppColors.successGreen,
    );

    final rateCard = _PaymentKpiCard(
      title: 'Collection Rate',
      value: '$percentStr%',
      subtitle: percent >= 0.8
          ? 'Healthy collection velocity'
          : (percent >= 0.5 ? 'Moderate recovery' : 'High arrears backlog'),
      icon: Icons.insights_rounded,
      accentColor: const Color(0xFF8B5CF6),
      bgColor: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
      progress: percent,
      progressColor: const Color(0xFF8B5CF6),
      badgeText: percent >= 0.8
          ? 'Optimal'
          : (percent >= 0.5 ? 'Normal' : 'Action Req.'),
      badgeColor: percent >= 0.8
          ? AppColors.successGreen
          : (percent >= 0.5 ? AppColors.warningOrange : AppColors.errorRed),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // Desktop: 4 cards across
        if (w >= 1024) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: billedCard),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: collectedCard),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: owedCard),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: rateCard),
            ],
          );
        }

        // Tablet: 2x2 grid
        if (w >= 600) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: billedCard),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: collectedCard),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: owedCard),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: rateCard),
                ],
              ),
            ],
          );
        }

        // Mobile: 1 column
        return Column(
          children: [
            billedCard,
            const SizedBox(height: AppSpacing.sm),
            collectedCard,
            const SizedBox(height: AppSpacing.sm),
            owedCard,
            const SizedBox(height: AppSpacing.sm),
            rateCard,
          ],
        );
      },
    );
  }
}

class _PaymentKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final double? progress;
  final Color? progressColor;
  final String? badgeText;
  final Color? badgeColor;

  const _PaymentKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    this.progress,
    this.progressColor,
    this.badgeText,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Icon and Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? accentColor).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor ?? accentColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Label
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Main Metric Value
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDark,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Optional Progress Indicator
          if (progress != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.lightGray.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressColor ?? accentColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Subtitle / Note
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.mediumGray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
