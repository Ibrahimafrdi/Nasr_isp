import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/theme/app_typography.dart';

class MetricCardWidget extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;
  final VoidCallback? onTap;
  final String? description;

  const MetricCardWidget({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
    this.onTap,
    this.description,
  }) : super(key: key);

  @override
  State<MetricCardWidget> createState() => _MetricCardWidgetState();
}

class _MetricCardWidgetState extends State<MetricCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: _isHovered
                  ? accentColor.withOpacity(0.2)
                  : AppColors.lightGray.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? accentColor.withOpacity(0.06)
                    : Colors.black.withOpacity(0.02),
                blurRadius: _isHovered ? 8 : 4,
                offset: Offset(0, _isHovered ? 2 : 1),
              ),
            ],
          ),
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon + Label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.mediumGray,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(widget.icon, size: 18, color: accentColor),
                ],
              ),

              // Value
              Text(
                widget.value,
                style: AppTypography.headingMedium.copyWith(
                  color: AppColors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              // Description (optional)
              if (widget.description != null) ...[
                SizedBox(height: AppSpacing.xs),
                Text(
                  widget.description!,
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.darkGray,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
