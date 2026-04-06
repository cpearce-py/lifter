import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:lifter/core/ui/themes/app_theme.dart';

// Data class (Keep this if it's in this file)
class MaxPullPoint {
  final DateTime date;
  final double leftMax;
  final double rightMax;
  MaxPullPoint({required this.date, required this.leftMax, required this.rightMax});
}

class MaxPullProgressionChart extends StatelessWidget {
  final List<MaxPullPoint> progressionData;

  const MaxPullProgressionChart({super.key, required this.progressionData});

  @override
  Widget build(BuildContext context) {
    // 1. Safety check for empty state: Give it a fixed height so the ChartCard doesn't collapse!
    if (progressionData.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Complete a Peak Load to see progress', 
            style: context.body.copyWith(color: context.textMuted),
          ),
        ),
      );
    }

    final leftColor = context.repeaterAccent; 
    final rightColor = context.setRestAccent; 

    // 2. Safe Max Y calculation (compare both hands!)
    double maxY = 10.0;
    double maxLeft = progressionData.map((e) => e.leftMax).reduce(max);
    double maxRight = progressionData.map((e) => e.rightMax).reduce(max);
    double absoluteMax = max(maxLeft, maxRight);
    
    if (absoluteMax > 0) {
      maxY = absoluteMax + (absoluteMax * 0.2); // Add 20% headroom
    }

    // 3. Safe Max X calculation (prevents divide-by-zero!)
    double maxX = (progressionData.length - 1).toDouble();
    if (maxX <= 0) maxX = 1.0;

    // 4. Safe Y-Axis Interval (prevents getEfficientInterval crash!)
    double yInterval = (maxY / 5).ceilToDouble();
    if (yInterval <= 0) yInterval = 5.0;

    // Map the spots
    final leftSpots = progressionData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.leftMax)).toList();
    final rightSpots = progressionData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.rightMax)).toList();

    // 5. The bulletproof SizedBox constraint!
    return SizedBox(
      height: 220,
      width: double.infinity, 
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: 0,
          maxY: maxY,
          
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval, // Safe interval
            verticalInterval: 1.0,         // Safe interval
            getDrawingHorizontalLine: (value) => FlLine(
              color: context.textPrimary.withOpacity(0.20), // Brighter lines!
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          
          lineTouchData: LineTouchData(
            getTouchLineStart: (barData, spotIndex) => 0, 
            getTouchLineEnd: (barData, spotIndex) => maxY, // Full height selection line!
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: context.textPrimary.withOpacity(0.4), 
                    strokeWidth: 2,
                    dashArray: [4, 4], 
                  ),
                  const FlDotData(show: true), 
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => context.textPrimary.withOpacity(0.8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) => LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} kg', // Add units for clarity!
                  TextStyle(color: context.background, fontWeight: FontWeight.bold),
                )).toList();
              },
            ),
          ),
          
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide X axis labels for this graph
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: yInterval, // Safe interval
                getTitlesWidget: (value, meta) {
                  // Only show whole numbers on the axis to keep it clean
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
          ),
          
          borderData: FlBorderData(show: false),
          
          lineBarsData: [
            // Left Hand Line
            LineChartBarData(
              spots: leftSpots,
              isCurved: true,
              preventCurveOverShooting: true, // No dipping below zero!
              color: leftColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true), 
              belowBarData: BarAreaData(
                show: true,
                color: leftColor.withOpacity(0.1),
              ),
            ),
            // Right Hand Line
            LineChartBarData(
              spots: rightSpots,
              isCurved: true,
              preventCurveOverShooting: true, // No dipping below zero!
              color: rightColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}
