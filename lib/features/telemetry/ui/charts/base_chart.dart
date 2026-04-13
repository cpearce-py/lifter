import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:lifter/core/ui/themes/app_theme.dart';

class BaseProgressionChart extends StatelessWidget {
  final double maxX;
  final double maxY;
  final double yInterval;
  final double xInterval;
  final List<double> verticalDividers;
  final List<LineChartBarData> lineBarsData;
  final Widget Function(double value) bottomLabelBuilder;
  final Widget Function(double value) leftLabelBuilder;
  final List<LineTooltipItem?> Function(List<LineBarSpot> touchedSpots)
  tooltipBuilder;

  const BaseProgressionChart({
    super.key,
    required this.maxX,
    required this.maxY,
    required this.yInterval,
    this.xInterval = 1.0,
    this.verticalDividers = const [],
    required this.lineBarsData,
    required this.bottomLabelBuilder,
    required this.leftLabelBuilder,
    required this.tooltipBuilder,
  });

  // Standardizes the "Hollow until touched" line look!
  static LineChartBarData createStandardLine({
    required List<FlSpot> spots,
    required Color color,
    required Color cardBackgroundColor,
    bool isCurved = false,
    double areaOpacity = 0.1,
  }) {
    final bool showDots = spots.length <= 20;

    return LineChartBarData(
      spots: spots,
      isCurved: isCurved,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: showDots,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: cardBackgroundColor, // Hollow center
            strokeWidth: 2,
            strokeColor: color, // Solid ring
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(areaOpacity),
      ),
    );
  }

  // Standardizes the "Pop to Solid" effect when hovering
  static List<TouchedSpotIndicatorData> _buildTouchedIndicators(
    LineChartBarData barData,
    List<int> spotIndexes,
    Color indicatorLineColor,
    Color cardBackgroundColor,
  ) {
    return spotIndexes.map((index) {
      return TouchedSpotIndicatorData(
        FlLine(
          color: indicatorLineColor.withOpacity(0.4),
          strokeWidth: 2,
          dashArray: [4, 4],
        ),
        FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, idx) {
            return FlDotCirclePainter(
              radius: 6, // Enlarges slightly
              color:
                  bar.color ??
                  indicatorLineColor, // Fills with the line's specific color!
              strokeWidth: 2,
              strokeColor: cardBackgroundColor,
            );
          },
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: MediaQuery.of(context).size.width - 72,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: 0,
          maxY: maxY,

          // --- STANDARDIZED GRID ---
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            verticalInterval: 1.0,
            getDrawingHorizontalLine: (value) {
              bool isTopOrBottom = value <= 0.1 || (value - maxY).abs() <= 0.1;
              return FlLine(
                // Note: Make sure your context extensions are imported here!
                color: isTopOrBottom
                    ? context.textPrimary.withOpacity(0.5)
                    : context.textPrimary.withOpacity(0.15),
                strokeWidth: isTopOrBottom ? 2 : 1,
                dashArray: isTopOrBottom ? null : [4, 4],
              );
            },
          ),

          // Vertical lines for division
          extraLinesData: ExtraLinesData(
            extraLinesOnTop: false, // Draws them BEHIND your data lines
            verticalLines: verticalDividers.map((x) {
              return VerticalLine(
                x: x,
                color: context.textPrimary.withOpacity(0.2), // Super subtle
                strokeWidth: 2,
                dashArray: [4, 4], // Dotted line effect
              );
            }).toList(),
          ),

          // --- STANDARDIZED TOUCH BEHAVIOR ---
          lineTouchData: LineTouchData(
            touchSpotThreshold: 99999,
            distanceCalculator: (touchPoint, spotPixelCoordinates) {
              return (touchPoint.dx - spotPixelCoordinates.dx).abs();
            },
            getTouchLineStart: (barData, spotIndex) => 0,
            getTouchLineEnd: (barData, spotIndex) => maxY,
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return _buildTouchedIndicators(
                barData,
                spotIndexes,
                context.textPrimary,
                context.cardBackground,
              );
            },
            touchTooltipData: LineTouchTooltipData(
              showOnTopOfTheChartBoxArea: true,
              fitInsideHorizontally: true,
              tooltipMargin: -16,
              tooltipPadding: EdgeInsets.all(6),
              getTooltipColor: (spot) => context.textPrimary.withOpacity(0.85),
              getTooltipItems: tooltipBuilder, // INJECTS CUSTOM TEXT!
            ),
          ),

          // --- STANDARDIZED TITLES ---
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: xInterval,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: bottomLabelBuilder(
                      value,
                    ), // INJECTS CUSTOM X LABELS!
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: leftLabelBuilder(value), // INJECTS CUSTOM Y LABELS!
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: lineBarsData, // INJECTS THE ACTUAL DATA LINES!
        ),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      ),
    );
  }
}
