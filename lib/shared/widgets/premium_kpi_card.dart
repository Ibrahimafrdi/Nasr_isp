import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/theme/app_typography.dart';

/// PremiumKPICard - Clean, minimal SaaS-style KPI card
/// 
/// Design:
/// - Clean white background
/// - Subtle shadow
/// - Professional spacing
/// - No excessive gradients
/// - Clear hierarchy: Icon + Title -> Main Value -> Trend
/// - Responsive and compact
/// 
/// Features:
/// - Optional accent color (primary blue by default)
/// - Trend indicator with icon
/// - Hover effects for interactivity
/// - Clean typography hierarchy
class PremiumKPICard extends StatefulWidget {
  final String title;
  final String value;
  final String? trend;
  final bool isTrendPositive;
  final IconData icon;
  final Color? accentColor;
  final VoidCallback? onTap;
  final String? subtitle;
  final double? customHeight;

  const PremiumKPICard({
    Key? key,
    required this.title,
    required this.value,
    this.trend,
    this.isTrendPositive = true,
    required this.icon,
    this.accentColor,
    this.onTap,
    this.subtitle,
    this.customHeight,
  }) : super(key: key);

  @override
  State<PremiumKPICard> createState() => _PremiumKPICardState();
}

class _PremiumKPICardState extends State<PremiumKPICard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? AppColors.primaryBlue;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: widget.customHeight ?? 160,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: _isHovered
                    ? accentColor.withOpacity(0.2)
                    : AppColors.lightGray.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? accentColor.withOpacity(0.08)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: _isHovered ? 12 : 6,
                  offset: Offset(0, _isHovered ? 4 : 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header: Icon + Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.mediumGray,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              widget.subtitle!,
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.darkGray,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 20,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),

                // Main Value
                Text(
                  widget.value,
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                // Trend (if present)
                if (widget.trend != null)
                  Row(
                    children: [
                      Icon(
                        widget.isTrendPositive
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 16,
                        color: widget.isTrendPositive
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        widget.trend!,
                        style: AppTypography.labelSmall.copyWith(
                          color: widget.isTrendPositive
                              ? AppColors.successGreen
                              : AppColors.errorRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
