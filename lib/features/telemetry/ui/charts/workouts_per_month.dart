import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:lifter/core/ui/themes/app_theme.dart';

class WorkoutsProgressionChart extends StatefulWidget {
  const WorkoutsProgressionChart({super.key});

  @override
  State<WorkoutsProgressionChart> createState() =>
      _WorkoutsProgressionChartState();
}

class _WorkoutsProgressionChartState extends State<WorkoutsProgressionChart> {
  String _selectedRange = '1Y';
  final List<String> _ranges = ['1W', '1M', '3M', '6M', 'YTD', '1Y'];

  List<FlSpot> _getSpotsForRange(String range) {
    switch (range) {
      case '1W':
        return const [
          FlSpot(0, 1),
          FlSpot(1, 0),
          FlSpot(2, 2),
          FlSpot(3, 1),
          FlSpot(4, 0),
          FlSpot(5, 1),
          FlSpot(6, 3),
        ];
      case '1M':
        return const [FlSpot(0, 3), FlSpot(1, 5), FlSpot(2, 4), FlSpot(3, 6)];
      case '3M':
        return const [FlSpot(0, 12), FlSpot(1, 15), FlSpot(2, 10)];
      case '6M':
        return const [
          FlSpot(0, 8),
          FlSpot(1, 10),
          FlSpot(2, 12),
          FlSpot(3, 7),
          FlSpot(4, 15),
          FlSpot(5, 14),
        ];
      case 'YTD':
        return const [FlSpot(0, 2), FlSpot(1, 4), FlSpot(2, 8), FlSpot(3, 12)];
      case '1Y':
      default:
        return const [
          FlSpot(0, 4),
          FlSpot(1, 6),
          FlSpot(2, 0),
          FlSpot(3, 8),
          FlSpot(4, 12),
          FlSpot(5, 10),
          FlSpot(6, 2),
          FlSpot(7, 0),
          FlSpot(8, 5),
          FlSpot(9, 7),
          FlSpot(10, 15),
          FlSpot(11, 14),
        ];
    }
  }

  String _getBottomLabel(double value, String range) {
    final int index = value.toInt();
    if (range == '1W') {
      const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      if (index >= 0 && index < days.length) return days[index];
    } else if (range == '1M') {
      return 'W${index + 1}';
    } else if (range == '1Y') {
      const months = [
        'J',
        'F',
        'M',
        'A',
        'M',
        'J',
        'J',
        'A',
        'S',
        'O',
        'N',
        'D',
      ];
      if (index >= 0 && index < months.length) return months[index];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final spots = _getSpotsForRange(_selectedRange);

    // THE PERFECT MATH FIX
    double maxWorkouts = 3.0; // Default fallback
    if (spots.isNotEmpty) {
      final highestValue = spots.map((s) => s.y).reduce(max);
      if (highestValue > 0) {
        // Add 15% headroom, then mathematically snap it up to the nearest multiple of 3!
        double target = highestValue + (highestValue * 0.15);
        maxWorkouts = (target / 3).ceil() * 3.0; 
      }
    }
    
    // Now the interval is guaranteed to be a perfectly clean integer!
    double yInterval = maxWorkouts / 3;

    double maxX = (spots.length - 1).toDouble();
    if (maxX <= 0) maxX = 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          child: LineChart(
            key: ValueKey(_selectedRange),
            LineChartData(
              minX: 0,
              maxX: maxX,
              minY: 0,
              maxY: maxWorkouts,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                verticalInterval: 1.0,
                getDrawingHorizontalLine: (value) {
                  bool isTopOrBottom =
                      value <= 0.1 || (value - maxWorkouts).abs() <= 0.1;
                  return FlLine(
                    // Brighter and thicker for the borders, subtle for the middle!
                    color: isTopOrBottom
                        ? context.textPrimary.withValues(alpha: 0.5)
                        : context.textPrimary.withValues(alpha: 0.15),
                    strokeWidth: isTopOrBottom ? 2 : 1,
                    dashArray: isTopOrBottom
                        ? null
                        : [4, 4], // Solid on edges, dashed in middle
                  );
                },
              ),
              borderData: FlBorderData(show: false),

              lineTouchData: LineTouchData(
                // Ensure line spans the whole page.
                getTouchLineStart: (barData, spotIndex) => 0,
                getTouchLineEnd: (barData, spotIndex) => maxWorkouts,
                touchSpotThreshold: 99999,
                distanceCalculator: (touchPoint, spotPixelCoordinate) {
                  return (touchPoint.dx - spotPixelCoordinate.dx).abs();
                },
                getTouchedSpotIndicator:
                    (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((index) {
                        return TouchedSpotIndicatorData(
                          FlLine(
                            color: context.textPrimary,
                            strokeWidth: 2,
                            dashArray: [4, 4],
                          ),
                          FlDotData(show: true),
                        );
                      }).toList();
                    },
                touchTooltipData: LineTouchTooltipData(
                  showOnTopOfTheChartBoxArea: true,
                  fitInsideHorizontally: true,
                  tooltipMargin: -8,
                  getTooltipColor: (spot) =>
                      context.textPrimary.withValues(alpha: 0.8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots
                        .map(
                          (spot) => LineTooltipItem(
                            '${spot.y.toInt()} workouts',
                            TextStyle(
                              color: context.background,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        .toList();
                  },
                ),
              ),

              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                // Left Axis 
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 != 0) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          value.toInt().toString(),
                          style: context.overline.copyWith(
                            color: context.textMuted,
                            fontWeight: FontWeight.normal,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),

                // Bottom axis tiles
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1.0,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      final label = _getBottomLabel(value, _selectedRange);
                      return Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(
                          label,
                          style: context.overline.copyWith(
                            color: context.textMuted,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  preventCurveOverShooting: true,
                  color: context.streakAccent,
                  barWidth: 1.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: context.background,
                        strokeWidth: 2,
                        strokeColor: context.streakAccent,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        context.streakAccent.withValues(alpha: 0.3),
                        context.streakAccent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Range Selector Controls
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: context.inputBackground,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _ranges.map((range) {
              final isSelected = _selectedRange == range;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedRange = range);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.cardBorder
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        range,
                        style: context.overline.copyWith(
                          color: isSelected
                              ? context.textPrimary
                              : context.textMuted,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
