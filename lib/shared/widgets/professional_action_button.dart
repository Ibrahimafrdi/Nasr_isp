import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/theme/app_typography.dart';

/// ProfessionalActionButton - Modern quick action button
/// 
/// Features:
/// - Clean design with icon and label
/// - Optional description text
/// - Hover effects
/// - Professional styling
/// - Icon color or background color option
class ProfessionalActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? description;
  final VoidCallback onTap;
  final Color accentColor;
  final double? width;
  final double? height;

  const ProfessionalActionButton({
    Key? key,
    required this.icon,
    required this.label,
    this.description,
    required this.onTap,
    required this.accentColor,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<ProfessionalActionButton> createState() =>
      _ProfessionalActionButtonState();
}

class _ProfessionalActionButtonState extends State<ProfessionalActionButton>
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
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: _isHovered
                    ? widget.accentColor.withOpacity(0.3)
                    : AppColors.lightGray.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? widget.accentColor.withOpacity(0.1)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: _isHovered ? 12 : 6,
                  offset: Offset(0, _isHovered ? 4 : 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Center(
                    child: Icon(
                      widget.icon,
                      size: 24,
                      color: widget.accentColor,
                    ),
                  ),
                ),

                SizedBox(height: AppSpacing.md),

                // Label
                Text(
                  widget.label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Description (optional)
                if (widget.description != null) ...[
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.description!,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.mediumGray,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
