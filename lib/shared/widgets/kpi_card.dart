import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
/// KPICard - Redesigned modern SaaS-style KPI statistic card.
/// Features:
/// - Minimal white background with subtle border
/// - Sleek hover scale up and color-tinted glow
/// - Smooth counting numeric value animation
/// - Custom Bezier wavy sparkline chart
/// - Fully responsive constraints preventing overflow
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
      end: 1.025,
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
    
    // Extract accent color from the first color in the gradient, defaulting to primary blue
    final Color accentColor = widget.gradient.isNotEmpty 
        ? widget.gradient.first 
        : AppColors.primaryBlue;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? accentColor.withOpacity(0.4)
                    : AppColors.lightGray.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? accentColor.withOpacity(0.08)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: _isHovered ? 16 : 8,
                  offset: Offset(0, _isHovered ? 6 : 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header Area: Title & Subtitle + Styled Icon Container
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
                                style: GoogleFonts.inter(
                                  color: AppColors.darkGray,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle!,
                                  style: GoogleFonts.inter(
                                    color: AppColors.mediumGray,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(_isHovered ? 0.14 : 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.icon,
                            color: accentColor,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                                style: GoogleFonts.inter(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              widget.trendWidget ?? (widget.trend != null
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (widget.isTrendPositive ? AppColors.successGreen : AppColors.errorRed).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            widget.isTrendPositive
                                                ? Icons.trending_up
                                                : Icons.trending_down,
                                            color: widget.isTrendPositive
                                                ? AppColors.successGreen
                                                : AppColors.errorRed,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            widget.trend!,
                                            style: GoogleFonts.inter(
                                              color: widget.isTrendPositive
                                                  ? AppColors.successGreen
                                                  : AppColors.errorRed,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
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
                          width: 70,
                          height: 32,
                          margin: const EdgeInsets.only(bottom: 2),
                          child: CustomPaint(
                            painter: SparklinePainter(
                              dataPoints: chartPoints,
                              lineColor: accentColor,
                              fillColor: accentColor.withOpacity(0.08),
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
