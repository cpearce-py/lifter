import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/telemetry/models.dart';
import 'package:lifter/features/telemetry/providers/chart_workout_provider.dart';
import 'package:lifter/features/telemetry/ui/charts/base_chart.dart';

class WorkoutsProgressionChart extends ConsumerStatefulWidget {
  const WorkoutsProgressionChart({super.key});

  @override
  ConsumerState<WorkoutsProgressionChart> createState() =>
      _WorkoutsProgressionChartState();
}

class _WorkoutsProgressionChartState
    extends ConsumerState<WorkoutsProgressionChart> {
  String _selectedRange = '1Y';

  String _getBottomLabel(double value, String range) {
    final int index = value.toInt();

    if (range == '1W' && index >= 0 && index < fullDays.length) {
      return fullDays[index][0];
    } else if (range == '1M') {
      return 'W${index + 1}';
    } else if (range == 'YTD') {
      final currentMonth = DateTime.now().month;
      if (index >= 0 && index < currentMonth) {
        if (currentMonth > 6) {
          return fullMonths[index][0];
        } else {
          return fullMonths[index].substring(0, 3);
        }
      }
    } else if (range == '3M' || range == '6M' || range == '1Y') {
      // Rolling month labels
      int maxIdx = range == '3M' ? 2 : (range == '6M' ? 5 : 11);
      int monthsAgo = maxIdx - index;
      int targetMonth = DateTime.now().month - monthsAgo;
      while (targetMonth <= 0) {
        targetMonth += 12;
      }
      return fullMonths[targetMonth - 1][0];
    }
    return '';
  }

  String _getTooltipLabel(double value, String range) {
    final int index = value.toInt();

    if (range == '1W' && index >= 0 && index < fullDays.length) {
      return fullDays[index];
    } else if (range == '1M') {
      return 'W${index + 1}';
    } else if (range == 'YTD') {
      final currentMonth = DateTime.now().month;
      if (index >= 0 && index < currentMonth) {
        return fullMonths[index];
      }
    } else if (range == '3M' || range == '6M' || range == '1Y') {
      // The exact same rolling math, but returning the FULL word!
      int maxIdx = range == '3M' ? 2 : (range == '6M' ? 5 : 11);
      int monthsAgo = maxIdx - index;
      int targetMonth = DateTime.now().month - monthsAgo;
      while (targetMonth <= 0) {
        targetMonth += 12;
      }
      return fullMonths[targetMonth - 1];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    // 1. Fetch data ONCE without .family
    final chartDataAsync = ref.watch(chartWorkoutsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        chartDataAsync.when(
          loading: () => const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) =>
              SizedBox(height: 220, child: Center(child: Text('Error: $err'))),
          data: (allWorkouts) {
            final now = DateTime.now();

            // 2. IN-MEMORY FILTERING
            final timeframeWorkouts = allWorkouts.where((w) {
              if (_selectedRange == '1W') {
                final start = now.subtract(Duration(days: now.weekday - 1));
                return w.dateDone.isAfter(start) ||
                    w.dateDone.isAtSameMomentAs(start);
              } else if (_selectedRange == '1M') {
                return w.dateDone.year == now.year &&
                    w.dateDone.month == now.month;
              } else if (_selectedRange == '3M') {
                final start = DateTime(now.year, now.month - 2, 1);
                return w.dateDone.isAfter(start) ||
                    w.dateDone.isAtSameMomentAs(start);
              } else if (_selectedRange == '6M') {
                final start = DateTime(now.year, now.month - 5, 1);
                return w.dateDone.isAfter(start) ||
                    w.dateDone.isAtSameMomentAs(start);
              } else if (_selectedRange == 'YTD') {
                return w.dateDone.year == now.year;
              } else {
                // 1Y
                final start = DateTime(now.year - 1, now.month, now.day);
                return w.dateDone.isAfter(start) ||
                    w.dateDone.isAtSameMomentAs(start);
              }
            }).toList();

            // 3. EXACT ZOOM BOUNDARIES
            double maxX = 1.0;
            if (_selectedRange == '1W') {
              maxX = 6.0;
            } else if (_selectedRange == '1M') {
              maxX = 3.0;
            } else if (_selectedRange == '3M') {
              maxX = 2.0;
            } else if (_selectedRange == '6M') {
              maxX = 5.0;
            } else if (_selectedRange == 'YTD') {
              maxX = (now.month > 1 ? now.month - 1 : 1).toDouble();
            } else {
              maxX = 11.0;
            }

            // 4. AGGREGATE WORKOUT COUNTS
            Map<int, double> counts = {};

            for (final w in timeframeWorkouts) {
              int xIndex = 0;

              if (_selectedRange == '1W') {
                xIndex = w.dateDone.weekday - 1;
              } else if (_selectedRange == '1M') {
                xIndex = (w.dateDone.day - 1) ~/ 7;
                if (xIndex > 3) xIndex = 3;
              } else if (_selectedRange == 'YTD') {
                xIndex = w.dateDone.month - 1;
              } else {
                // 3M, 6M, 1Y
                int monthsAgo =
                    (now.year - w.dateDone.year) * 12 +
                    now.month -
                    w.dateDone.month;
                if (_selectedRange == '3M') {
                  xIndex = 2 - monthsAgo;
                } else if (_selectedRange == '6M') {
                  xIndex = 5 - monthsAgo;
                } else {
                  xIndex = 11 - monthsAgo;
                }
              }

              if (xIndex < 0) continue;

              counts[xIndex] = (counts[xIndex] ?? 0) + 1;
            }

            // Fill the spots array, ensuring empty buckets get a 0 so the line drops to the floor
            List<FlSpot> spots = [];
            for (int i = 0; i <= maxX.toInt(); i++) {
              spots.add(FlSpot(i.toDouble(), counts[i] ?? 0.0));
            }

            // 5. Y-AXIS MATH (Snap to multiples of 3 for 4 perfect grid lines)
            double maxWorkouts = 3.0;
            if (spots.isNotEmpty) {
              final highestValue = spots.map((s) => s.y).reduce(max);
              if (highestValue > 0) {
                double target = highestValue + (highestValue * 0.15);
                maxWorkouts = (target / 3).ceil() * 3.0;
              }
            }
            double yInterval = maxWorkouts / 3;

            // 6. BUILD THE CHART
            return BaseProgressionChart(
              maxX: maxX,
              maxY: maxWorkouts,
              yInterval: yInterval,

              // Define the custom line
              lineBarsData: [
                BaseProgressionChart.createStandardLine(
                  spots: spots,
                  color: context.streakAccent, // The custom blue color
                  cardBackgroundColor: context.cardBackground,
                  isCurved: false, // Straight lines!
                ),
              ],

              // Inject custom Axis Text
              bottomLabelBuilder: (value) => Text(
                _getBottomLabel(value, _selectedRange),
                style: context.overline.copyWith(color: context.textMuted),
              ),
              leftLabelBuilder: (value) => Text(
                value.toInt().toString(),
                style: context.overline.copyWith(
                  color: context.textMuted,
                  fontWeight: FontWeight.normal,
                ),
                textAlign: TextAlign.right,
              ),

              // Inject Custom Tooltips
              tooltipBuilder: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final label = _getTooltipLabel(spot.x, _selectedRange);
                  return LineTooltipItem(
                    '${spot.y.toInt()} workouts',
                    TextStyle(
                      color: context.textPrimaryInv,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.left,
                    children: [
                      TextSpan(
                        text: '\n$label',
                        style: TextStyle(
                          color: context.textPrimaryInv.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            );
          },
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ranges.map((range) {
            final isSelected = _selectedRange == range;
            return GestureDetector(
              onTap: () => setState(() => _selectedRange = range),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.textPrimary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  range,
                  style: context.body.copyWith(
                    color: isSelected ? context.textPrimary : context.textMuted,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
