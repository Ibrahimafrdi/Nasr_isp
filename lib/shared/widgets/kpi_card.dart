import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/core/theme/app_typography.dart';
import 'package:nasr_isp/core/theme/app_shadows.dart';

/// KPICard - Modern dashboard KPI statistics card with animated counters, wavy sparkline charts, and hover glows.
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
  final List<double>? sparklineData;

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
    this.sparklineData,
  }) : super(key: key);

  @override
  State<KPICard> createState() => _KPICardState();
}

class _KPICardState extends State<KPICard> with SingleTickerProviderStateMixin {
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<double> chartPoints = widget.sparklineData ?? [5, 6, 5, 7, 6, 8, 9, 8, 10];

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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: widget.gradient.first.withOpacity(_isHovered ? 0.35 : 0.15),
                  blurRadius: _isHovered ? 20 : 10,
                  offset: Offset(0, _isHovered ? 10 : 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.04),
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
                    // Header Area: Title & Subtitle + Floating Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  widget.subtitle!,
                                  style: AppTypography.captionSmall.copyWith(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(_isHovered ? 0.25 : 0.15),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Value, Trend Pill & Custom Painted Wavy Sparkline Chart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left: Counting numeric value and trend pill
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedCounter(
                                value: widget.value,
                                style: AppTypography.displaySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              widget.trendWidget ?? (widget.trend != null
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            widget.isTrendPositive
                                                ? Icons.trending_up
                                                : Icons.trending_down,
                                            color: widget.isTrendPositive
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.8),
                                            size: 13,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.trend!,
                                            style: AppTypography.bodySmall.copyWith(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink()),
                            ],
                          ),
                        ),
                        // Right: Wavy dynamic Sparkline Line Chart
                        Container(
                          width: 80,
                          height: 38,
                          margin: const EdgeInsets.only(bottom: 4),
                          child: CustomPaint(
                            painter: SparklinePainter(
                              dataPoints: chartPoints,
                              lineColor: Colors.white.withOpacity(0.85),
                              fillColor: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),
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

/// Dynamic implicitly animated number counters parsing integer or float parts and preserving static tokens.
class AnimatedCounter extends StatelessWidget {
  final String value;
  final TextStyle style;

  const AnimatedCounter({
    Key? key,
    required this.value,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RegExp numRegex = RegExp(r'[0-9]+(?:\.[0-9]+)?');
    final String numericString = numRegex.firstMatch(value.replaceAll(',', ''))?.group(0) ?? '';
    final double targetValue = double.tryParse(numericString) ?? 0.0;

    final int numberStartIdx = value.indexOf(RegExp(r'[0-9]'));
    final String prefix = numberStartIdx > 0 ? value.substring(0, numberStartIdx) : '';
    
    final String cleanValueForSuffix = value.replaceAll(',', '');
    final int numberEndIdx = cleanValueForSuffix.indexOf(numericString) + numericString.length;
    final String suffix = numberEndIdx < cleanValueForSuffix.length
        ? value.substring(value.indexOf(cleanValueForSuffix.substring(numberEndIdx)))
        : '';

    final bool isInteger = !numericString.contains('.');

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: targetValue),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutQuint,
      builder: (context, val, child) {
        String formattedValue;
        if (isInteger) {
          formattedValue = _formatWithCommas(val.toInt().toString());
        } else {
          formattedValue = val.toStringAsFixed(1);
        }
        return Text(
          '$prefix$formattedValue$suffix',
          style: style,
        );
      },
    );
  }

  String _formatWithCommas(String numberStr) {
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numberStr.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }
}

/// CustomPainter that renders sleek and smooth Bezier wavy sparkline charts inside statistical cards.
class SparklinePainter extends CustomPainter {
  final List<double> dataPoints;
  final Color lineColor;
  final Color fillColor;

  SparklinePainter({
    required this.dataPoints,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty || dataPoints.length < 2) return;

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final path = Path();
    final fillPath = Path();

    final double widthStep = size.width / (dataPoints.length - 1);
    final double max = dataPoints.reduce((a, b) => a > b ? a : b);
    final double min = dataPoints.reduce((a, b) => a < b ? a : b);
    final double range = max - min == 0 ? 1 : max - min;

    double x(int index) => index * widthStep;
    double y(int index) {
      final double normalized = (dataPoints[index] - min) / range;
      return size.height - (normalized * (size.height - 4)) - 2;
    }

    path.moveTo(x(0), y(0));
    fillPath.moveTo(x(0), size.height);
    fillPath.lineTo(x(0), y(0));

    for (int i = 0; i < dataPoints.length - 1; i++) {
      final double x1 = x(i);
      final double y1 = y(i);
      final double x2 = x(i + 1);
      final double y2 = y(i + 1);
      final double cx = (x1 + x2) / 2;

      path.cubicTo(cx, y1, cx, y2, x2, y2);
      fillPath.cubicTo(cx, y1, cx, y2, x2, y2);
    }

    fillPath.lineTo(x(dataPoints.length - 1), size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [fillColor, fillColor.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
