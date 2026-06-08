import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/theme/app_typography.dart';

enum AlertType { info, warning, error, success }

/// AlertPanel - Premium alert card supporting dismiss animations and modern hover scaling.
class AlertPanel extends StatefulWidget {
  final AlertType type;
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onActionTap;
  final String? actionLabel;
  final bool dismissible;
  final VoidCallback? onDismiss;

  const AlertPanel({
    Key? key,
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    this.onActionTap,
    this.actionLabel,
    this.dismissible = true,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<AlertPanel> createState() => _AlertPanelState();
}

class _AlertPanelState extends State<AlertPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _sizeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _animController.forward();
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    }
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case AlertType.info:
        return AppColors.skyBlue;
      case AlertType.warning:
        return const Color(0xFFFEF3C7);
      case AlertType.error:
        return const Color(0xFFFEE2E2);
      case AlertType.success:
        return const Color(0xFFDCFCE7);
    }
  }

  Color _getTextColor() {
    switch (widget.type) {
      case AlertType.info:
        return AppColors.infoBlue;
      case AlertType.warning:
        return const Color(0xFF92400E);
      case AlertType.error:
        return const Color(0xFF7F1D1D);
      case AlertType.success:
        return const Color(0xFF166534);
    }
  }

  Color _getIconBackgroundColor() {
    switch (widget.type) {
      case AlertType.info:
        return AppColors.infoBlue.withOpacity(0.15);
      case AlertType.warning:
        return AppColors.warningOrange.withOpacity(0.15);
      case AlertType.error:
        return AppColors.errorRed.withOpacity(0.15);
      case AlertType.success:
        return AppColors.successGreen.withOpacity(0.15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = _getTextColor();

    return SizeTransition(
      sizeFactor: _sizeAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(bottom: _isHovered ? 2 : 0),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: _isHovered
                    ? textColor.withOpacity(0.4)
                    : textColor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: textColor.withOpacity(_isHovered ? 0.12 : 0.06),
                  blurRadius: _isHovered ? 12 : 6,
                  offset: Offset(0, _isHovered ? 4 : 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _getIconBackgroundColor(),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(widget.icon, color: textColor, size: 24),
                ),
                SizedBox(width: AppSpacing.lg),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTypography.headingSmall.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.message,
                        style: AppTypography.bodySmall.copyWith(
                          color: textColor.withOpacity(0.85),
                          fontSize: 12.5,
                        ),
                      ),
                      if (widget.onActionTap != null &&
                          widget.actionLabel != null) ...[
                        SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: widget.onActionTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: textColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.dismissible) ...[
                  SizedBox(width: AppSpacing.lg),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _handleDismiss,
                      child: Icon(
                        Icons.close,
                        color: textColor.withOpacity(0.6),
                        size: 20,
                      ),
                    ),
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
