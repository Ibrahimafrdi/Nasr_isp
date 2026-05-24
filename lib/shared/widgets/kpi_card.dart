import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/theme/app_typography.dart';
import 'package:nasr_isp/core/theme/app_shadows.dart';

class KPICard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final String? trend;
  final bool isTrendPositive;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;
  final Widget? trendWidget;

  const KPICard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    this.trend,
    this.isTrendPositive = true,
    required this.icon,
    required this.gradient,
    this.onTap,
    this.trendWidget,
  }) : super(key: key);

  @override
  State<KPICard> createState() => _KPICardState();
}

class _KPICardState extends State<KPICard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: AppShadows.medium,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header with Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (widget.subtitle != null) ...[
                                SizedBox(height: AppSpacing.xs),
                                Text(
                                  widget.subtitle!,
                                  style: AppTypography.captionSmall.copyWith(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.lg),
                    // Value and Trend
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.value,
                          style: AppTypography.displaySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.trend != null ||
                            widget.trendWidget != null) ...[
                          SizedBox(height: AppSpacing.sm),
                          widget.trendWidget ??
                              Row(
                                children: [
                                  Icon(
                                    widget.isTrendPositive
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 16,
                                  ),
                                  SizedBox(width: AppSpacing.xs),
                                  Text(
                                    widget.trend ?? '',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
