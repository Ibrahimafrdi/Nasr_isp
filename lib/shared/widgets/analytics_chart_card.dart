import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_fonts.dart';
import 'package:nasr_isp/core/theme/app_decorations.dart';

class AnalyticsChartCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String chartType;
  final List<FlSpot>? data;
  final Color? lineColor;
  final Color? fillColor;
  final List<PieChartSectionData>? pieData;
  final List<BarChartGroupData>? barData;

  const AnalyticsChartCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.chartType = 'line',
    this.data,
    this.lineColor,
    this.fillColor,
    this.pieData,
    this.barData,
  }) : super(key: key);

  @override
  State<AnalyticsChartCard> createState() => _AnalyticsChartCardState();
}

class _AnalyticsChartCardState extends State<AnalyticsChartCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppDecorations.borderRadius),
      child: Container(
        height: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: AppDecorations.borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface, AppColors.surface.withOpacity(0.95)],
          ),
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
                      Text(widget.title, style: AppFonts.headlineMedium),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(widget.subtitle!, style: AppFonts.bodyMediumMuted),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColors.onBackground.withOpacity(0.5),
                  ),
                  onSelected: (value) {
                    // Handle menu selection
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download, color: AppColors.grey),
                          const SizedBox(width: 8),
                          Text('Export Data', style: AppFonts.bodyMedium),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, color: AppColors.grey),
                          const SizedBox(width: 8),
                          Text('Share', style: AppFonts.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final lineColor = widget.lineColor ?? AppColors.primary;
    final fillColor = widget.fillColor ?? lineColor.withOpacity(0.15);

    switch (widget.chartType) {
      case 'pie':
        return _buildPieChart();
      case 'bar':
        return _buildBarChart();
      case 'area':
        return _buildAreaChart();
      case 'line':
      default:
        return _buildLineChart();
    }
  }

  Widget _buildPieChart() {
    final pieData = widget.pieData ?? _getDefaultPieData();

    return PieChart(
      PieChartData(
        sections: pieData,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        startDegreeOffset: -90,
        pieTouchData: PieTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Handle touch events
          },
        ),
      ),
    );
  }

  Widget _buildAreaChart() {
    final chartData = widget.data ?? _getDefaultData();
    final lineColor = widget.lineColor ?? AppColors.primary;
    final fillColor = widget.fillColor ?? lineColor.withOpacity(0.15);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.onBackground.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppColors.onBackground.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const titles = [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun',
                ];
                if (value >= 0 && value < titles.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      titles[value.toInt()],
                      style: AppFonts.bodySmallMuted,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}K',
                  style: AppFonts.bodySmallMuted,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.onBackground.withOpacity(0.1)),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 5,
        lineBarsData: [
          LineChartBarData(
            spots: chartData,
            isCurved: true,
            gradient: LinearGradient(
              colors: [lineColor, lineColor.withOpacity(0.8)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [fillColor, fillColor.withOpacity(0.3)],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBorder: BorderSide(color: lineColor),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  '${touchedSpot.y.toStringAsFixed(1)}K',
                  AppFonts.labelMedium.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: AppFonts.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final chartData = widget.data ?? _getDefaultData();
    final lineColor = widget.lineColor ?? AppColors.primary;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBorder: BorderSide(color: AppColors.primary),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()}%',
                AppFonts.labelMedium.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: AppFonts.bold,
                ),
              );
            },
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
                const titles = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                if (value >= 0 && value < titles.length) {
                  return Text(
                    titles[value.toInt()],
                    style: AppFonts.bodySmallMuted,
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: AppFonts.bodySmallMuted,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.onBackground.withOpacity(0.1)),
        ),
        barGroups: List.generate(
          chartData.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: chartData[index].y,
                color: lineColor,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.onBackground.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final chartData = widget.data ?? _getDefaultData();
    final lineColor = widget.lineColor ?? AppColors.primary;
    final fillColor = widget.fillColor ?? lineColor.withOpacity(0.15);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.onBackground.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppColors.onBackground.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const titles = [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun',
                ];
                if (value >= 0 && value < titles.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      titles[value.toInt()],
                      style: AppFonts.bodySmallMuted,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}K',
                  style: AppFonts.bodySmallMuted,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.onBackground.withOpacity(0.1)),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 5,
        lineBarsData: [
          LineChartBarData(
            spots: chartData,
            isCurved: true,
            gradient: LinearGradient(
              colors: [lineColor, lineColor.withOpacity(0.8)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: lineColor,
                  strokeWidth: 2,
                  strokeColor: AppColors.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [fillColor, fillColor.withOpacity(0.1)],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBorder: BorderSide(color: lineColor),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  '${touchedSpot.y.toStringAsFixed(1)}K',
                  AppFonts.labelMedium.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: AppFonts.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<FlSpot> _getDefaultData() {
    return [
      const FlSpot(0, 2.2),
      const FlSpot(1, 2.8),
      const FlSpot(2, 2.1),
      const FlSpot(3, 3.2),
      const FlSpot(4, 2.9),
      const FlSpot(5, 3.8),
      const FlSpot(6, 3.1),
    ];
  }

  List<PieChartSectionData> _getDefaultPieData() {
    return [
      PieChartSectionData(
        color: AppColors.primary,
        value: 40,
        title: '40%',
        radius: 50,
        titleStyle: AppFonts.labelMedium.copyWith(
          color: AppColors.onPrimary,
          fontWeight: AppFonts.bold,
        ),
      ),
      PieChartSectionData(
        color: AppColors.success,
        value: 30,
        title: '30%',
        radius: 50,
        titleStyle: AppFonts.labelMedium.copyWith(
          color: AppColors.onPrimary,
          fontWeight: AppFonts.bold,
        ),
      ),
      PieChartSectionData(
        color: AppColors.warning,
        value: 20,
        title: '20%',
        radius: 50,
        titleStyle: AppFonts.labelMedium.copyWith(
          color: AppColors.onPrimary,
          fontWeight: AppFonts.bold,
        ),
      ),
      PieChartSectionData(
        color: AppColors.info,
        value: 10,
        title: '10%',
        radius: 50,
        titleStyle: AppFonts.labelMedium.copyWith(
          color: AppColors.onPrimary,
          fontWeight: AppFonts.bold,
        ),
      ),
    ];
  }
}
