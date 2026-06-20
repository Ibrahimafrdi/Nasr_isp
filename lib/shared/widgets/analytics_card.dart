import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_spacing.dart';

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
  const AnalyticsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isWide = width >= 1100;

        if (isWide) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: const RevenueChartCard()),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: const CustomerGrowthChartCard()),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: const PackageDistributionChartCard()),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: const PaymentStatisticsChartCard()),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              const RevenueChartCard(),
              const SizedBox(height: AppSpacing.lg),
              const CustomerGrowthChartCard(),
              const SizedBox(height: AppSpacing.lg),
              const PackageDistributionChartCard(),
              const SizedBox(height: AppSpacing.lg),
              const PaymentStatisticsChartCard(),
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

  const BaseChartCard({
    Key? key,
    required this.title,
    this.subtitle,
    required this.chart,
    this.footer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
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
  const RevenueChartCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseChartCard(
      title: 'Revenue Analytics',
      subtitle: 'Monthly earnings (PKR) over past 6 months',
      chart: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 100000,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                  if (value >= 0 && value < months.length) {
                    return Text(
                      months[value.toInt()],
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.darkGray),
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
                interval: 100000,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${(value / 1000).toStringAsFixed(0)}K',
                    style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.darkGray),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
              left: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
          ),
          minX: 0,
          maxX: 5,
          minY: 0,
          maxY: 500000,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 180000),
                FlSpot(1, 210000),
                FlSpot(2, 245000),
                FlSpot(3, 230000),
                FlSpot(4, 285000),
                FlSpot(5, 320000),
              ],
              isCurved: true,
              color: AppColors.primaryBlue,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primaryBlue,
                    strokeColor: Colors.white,
                    strokeWidth: 2,
                  );
                },
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
  const CustomerGrowthChartCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseChartCard(
      title: 'Customer Growth',
      subtitle: 'Net active internet subscribers by month',
      chart: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 50,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                  if (value >= 0 && value < months.length) {
                    return Text(
                      months[value.toInt()],
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.darkGray),
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
                interval: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.darkGray),
                  );
                },
                reservedSize: 32,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
              left: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
          ),
          minX: 0,
          maxX: 5,
          minY: 100,
          maxY: 300,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 120),
                FlSpot(1, 145),
                FlSpot(2, 172),
                FlSpot(3, 210),
                FlSpot(4, 256),
                FlSpot(5, 284),
              ],
              isCurved: true,
              color: AppColors.successGreen,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.successGreen,
                    strokeColor: Colors.white,
                    strokeWidth: 2,
                  );
                },
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
  const PackageDistributionChartCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseChartCard(
      title: 'Package Distribution',
      subtitle: 'Popular subscription packages by active users',
      chart: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 45,
          startDegreeOffset: -90,
          sections: [
            PieChartSectionData(
              color: AppColors.primaryBlue,
              value: 45,
              title: '45%',
              radius: 40,
              titleStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              color: AppColors.successGreen,
              value: 30,
              title: '30%',
              radius: 40,
              titleStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              color: AppColors.warningOrange,
              value: 15,
              title: '15%',
              radius: 40,
              titleStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              color: Colors.purple[400]!,
              value: 10,
              title: '10%',
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
        _buildLegendItem('10 Mbps', AppColors.primaryBlue),
        const SizedBox(width: 14),
        _buildLegendItem('25 Mbps', AppColors.successGreen),
        const SizedBox(width: 14),
        _buildLegendItem('50 Mbps', AppColors.warningOrange),
        const SizedBox(width: 14),
        _buildLegendItem('Others', Colors.purple[400]!),
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
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.charcoal, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class PaymentStatisticsChartCard extends StatelessWidget {
  const PaymentStatisticsChartCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseChartCard(
      title: 'Payment Statistics',
      subtitle: 'Invoiced vs Paid amount (PKR) by payment method',
      chart: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: 200000,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const methods = ['Cash', 'Bank Transfer', 'Credit Card'];
                  if (value >= 0 && value < methods.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        methods[value.toInt()],
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.darkGray),
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
                interval: 50000,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${(value / 1000).toStringAsFixed(0)}K',
                    style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.darkGray),
                  );
                },
                reservedSize: 36,
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 50000,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
              left: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
          ),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(toY: 150000, color: AppColors.primaryBlue, width: 12, borderRadius: BorderRadius.circular(3)),
                BarChartRodData(toY: 135000, color: AppColors.successGreen, width: 12, borderRadius: BorderRadius.circular(3)),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(toY: 185000, color: AppColors.primaryBlue, width: 12, borderRadius: BorderRadius.circular(3)),
                BarChartRodData(toY: 180000, color: AppColors.successGreen, width: 12, borderRadius: BorderRadius.circular(3)),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(toY: 90000, color: AppColors.primaryBlue, width: 12, borderRadius: BorderRadius.circular(3)),
                BarChartRodData(toY: 82000, color: AppColors.successGreen, width: 12, borderRadius: BorderRadius.circular(3)),
              ],
            ),
          ],
        ),
      ),
      footer: [
        _buildLegendItem('Invoiced', AppColors.primaryBlue),
        const SizedBox(width: 24),
        _buildLegendItem('Collected', AppColors.successGreen),
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
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.charcoal, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
