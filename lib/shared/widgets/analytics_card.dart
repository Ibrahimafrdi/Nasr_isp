import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';

/// Redesigned Analytics Section containing the 4 required charts:
/// - Revenue Analytics (Area Chart)
/// - Customer Growth (Curved Line Chart)
/// - Package Distribution (Pie Chart)
/// - Payment Statistics (Bar Chart)
///
/// Responsive layout is automatically handled:
/// - Desktop (width >= 1100): Side-by-side 2-column grid.
/// - Tablet & Mobile: Single column vertical stack.
class AnalyticsSection extends StatelessWidget {
  final List<double> monthlyRevenue6;
  final List<double> customerGrowth6;
  final Map<String, int> connectionTypeDist;
  final Map<String, double> paymentByMethod;

  const AnalyticsSection({
    Key? key,
    required this.monthlyRevenue6,
    required this.customerGrowth6,
    required this.connectionTypeDist,
    required this.paymentByMethod,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 1100;
        final deviceType = Responsive.deviceTypeForWidth(constraints.maxWidth);
        double chartHeight;
        switch (deviceType) {
          case DeviceType.mobile:
            chartHeight = 200;
            break;
          case DeviceType.tablet:
            chartHeight = 260;
            break;
          case DeviceType.desktop:
            chartHeight = 330;
            break;
        }

        if (isWide) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RevenueChartCard(
                      monthlyRevenue6: monthlyRevenue6,
                      height: chartHeight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: CustomerGrowthChartCard(
                      customerGrowth6: customerGrowth6,
                      height: chartHeight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: PackageDistributionChartCard(
                      connectionTypeDist: connectionTypeDist,
                      height: chartHeight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: PaymentStatisticsChartCard(
                      paymentByMethod: paymentByMethod,
                      height: chartHeight,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              RevenueChartCard(
                monthlyRevenue6: monthlyRevenue6,
                height: chartHeight,
              ),
              const SizedBox(height: AppSpacing.lg),
              CustomerGrowthChartCard(
                customerGrowth6: customerGrowth6,
                height: chartHeight,
              ),
              const SizedBox(height: AppSpacing.lg),
              PackageDistributionChartCard(
                connectionTypeDist: connectionTypeDist,
                height: chartHeight,
              ),
              const SizedBox(height: AppSpacing.lg),
              PaymentStatisticsChartCard(
                paymentByMethod: paymentByMethod,
                height: chartHeight,
              ),
            ],
          );
        }
      },
    );
  }
}

/// Abstract base style for analytics card containers to match the minimal Stripe aesthetic
class BaseChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget chart;
  final List<Widget>? footer;
  final double height;

  const BaseChartCard({
    Key? key,
    required this.title,
    this.subtitle,
    required this.chart,
    this.footer,
    this.height = 330,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: chart),
          if (footer != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: footer!,
            ),
          ],
        ],
      ),
    );
  }
}

class RevenueChartCard extends StatelessWidget {
  final List<double> monthlyRevenue6;
  final double height;

  const RevenueChartCard({
    Key? key,
    required this.monthlyRevenue6,
    this.height = 330,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Build month labels for last 6 months
    final now = DateTime.now();
    final monthLabels = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i));
      const names = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return names[d.month - 1];
    });

    final spots = List.generate(
      monthlyRevenue6.length,
      (i) => FlSpot(i.toDouble(), monthlyRevenue6[i]),
    );

    final maxY = monthlyRevenue6.isEmpty
        ? 500000.0
        : (monthlyRevenue6.reduce((a, b) => a > b ? a : b) * 1.3)
            .clamp(10000.0, double.infinity);

    return BaseChartCard(
      title: 'Revenue Analytics',
      subtitle: 'Monthly collected payments (PKR) — last 6 months',
      height: height,
      chart: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < monthLabels.length) {
                    return Text(
                      monthLabels[idx],
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppColors.darkGray),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 22,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY / 5,
                getTitlesWidget: (value, meta) => Text(
                  '${(value / 1000).toStringAsFixed(0)}K',
                  style: GoogleFonts.inter(
                      fontSize: 9.5, color: AppColors.darkGray),
                ),
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2), width: 1),
              left: BorderSide(
                  color: Colors.grey.withOpacity(0.2), width: 1),
            ),
          ),
          minX: 0,
          maxX: 5,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primaryBlue,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primaryBlue,
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.12),
                    AppColors.primaryBlue.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerGrowthChartCard extends StatelessWidget {
  final List<double> customerGrowth6;
  final double height;

  const CustomerGrowthChartCard({
    Key? key,
    required this.customerGrowth6,
    this.height = 330,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabels = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i));
      const names = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return names[d.month - 1];
    });

    final spots = List.generate(
      customerGrowth6.length,
      (i) => FlSpot(i.toDouble(), customerGrowth6[i]),
    );

    final maxY = customerGrowth6.isEmpty
        ? 100.0
        : (customerGrowth6.reduce((a, b) => a > b ? a : b) * 1.3)
            .clamp(10.0, double.infinity);

    final minY = customerGrowth6.isEmpty
        ? 0.0
        : (customerGrowth6.reduce((a, b) => a < b ? a : b) * 0.8)
            .clamp(0.0, double.infinity);

    return BaseChartCard(
      title: 'Customer Growth',
      subtitle: 'Cumulative active subscribers by month',
      height: height,
      chart: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < monthLabels.length) {
                    return Text(
                      monthLabels[idx],
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppColors.darkGray),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 22,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (maxY - minY) / 5,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: GoogleFonts.inter(
                      fontSize: 9.5, color: AppColors.darkGray),
                ),
                reservedSize: 32,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2), width: 1),
              left: BorderSide(
                  color: Colors.grey.withOpacity(0.2), width: 1),
            ),
          ),
          minX: 0,
          maxX: 5,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.successGreen,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.successGreen,
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.successGreen.withOpacity(0.12),
                    AppColors.successGreen.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PackageDistributionChartCard extends StatelessWidget {
  final Map<String, int> connectionTypeDist;
  final double height;

  const PackageDistributionChartCard({
    Key? key,
    required this.connectionTypeDist,
    this.height = 330,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final wireless = (connectionTypeDist['wireless'] ?? 0).toDouble();
    final fiber = (connectionTypeDist['fiber'] ?? 0).toDouble();
    final total = wireless + fiber;

    final wirelessPct = total > 0 ? (wireless / total * 100) : 0.0;
    final fiberPct = total > 0 ? (fiber / total * 100) : 0.0;

    return BaseChartCard(
      title: 'Connection Distribution',
      subtitle: 'Wireless vs Fiber active subscribers',
      height: height,
      chart: total == 0
          ? Center(
              child: Text(
                'No customer data yet',
                style: GoogleFonts.inter(color: AppColors.darkGray),
              ),
            )
          : PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 45,
                startDegreeOffset: -90,
                sections: [
                  PieChartSectionData(
                    color: AppColors.primaryBlue,
                    value: wirelessPct,
                    title: '${wirelessPct.toStringAsFixed(0)}%',
                    radius: 40,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.purple,
                    value: fiberPct,
                    title: '${fiberPct.toStringAsFixed(0)}%',
                    radius: 40,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
      footer: [
        _buildLegendItem('Wireless (${wireless.toInt()})', AppColors.primaryBlue),
        const SizedBox(width: 20),
        _buildLegendItem('Fiber (${fiber.toInt()})', Colors.purple),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.charcoal,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class PaymentStatisticsChartCard extends StatelessWidget {
  final Map<String, double> paymentByMethod;
  final double height;

  const PaymentStatisticsChartCard({
    Key? key,
    required this.paymentByMethod,
    this.height = 330,
  }) : super(key: key);

  String _displayName(String method) {
    switch (method.toLowerCase().trim()) {
      case 'cash': return 'Cash';
      case 'bank':
      case 'bank transfer': return 'Bank';
      case 'jazzcash': return 'JazzCash';
      case 'easypaisa': return 'EasyPaisa';
      default: return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final methods = paymentByMethod.keys.toList();
    final values = methods.map((k) => paymentByMethod[k]!).toList();

    final maxY = values.isEmpty
        ? 100000.0
        : (values.reduce((a, b) => a > b ? a : b) * 1.3)
            .clamp(10000.0, double.infinity);

    final colors = [
      AppColors.primaryBlue,
      AppColors.successGreen,
      AppColors.warningOrange,
      Colors.purple,
    ];

    return BaseChartCard(
      title: 'Payment by Method',
      subtitle: 'Total collected (PKR) per payment method',
      height: height,
      chart: methods.isEmpty
          ? Center(
              child: Text(
                'No payment data yet',
                style: GoogleFonts.inter(color: AppColors.darkGray),
              ),
            )
          : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < methods.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _displayName(methods[idx]),
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.darkGray),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 26,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) => Text(
                        '${(value / 1000).toStringAsFixed(0)}K',
                        style: GoogleFonts.inter(
                            fontSize: 9.5, color: AppColors.darkGray),
                      ),
                      reservedSize: 36,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2), width: 1),
                    left: BorderSide(
                        color: Colors.grey.withOpacity(0.2), width: 1),
                  ),
                ),
                barGroups: List.generate(methods.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        color: colors[i % colors.length],
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
      footer: List.generate(methods.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors[i % colors.length],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _displayName(methods[i]),
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }),
    );
  }
}
