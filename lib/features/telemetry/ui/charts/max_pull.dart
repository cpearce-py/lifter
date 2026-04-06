import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/telemetry/models.dart';
import 'package:lifter/features/telemetry/providers/chart_workout_provider.dart';
import 'package:lifter/features/telemetry/ui/charts/base_chart.dart';


class MaxPullProgressionChart extends ConsumerStatefulWidget {
  const MaxPullProgressionChart({super.key});

  @override
  ConsumerState<MaxPullProgressionChart> createState() =>
      _MaxPullProgressionChartState();
}

class _MaxPullProgressionChartState
    extends ConsumerState<MaxPullProgressionChart> {
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
      if (index >= 0 && index < currentMonth) return fullMonths[index];
    } else if (range == '3M' || range == '6M' || range == '1Y') {
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
    final chartDataAsync = ref.watch(chartWorkoutsProvider);

    final leftColor = context.repeaterAccent;
    final rightColor = context.setRestAccent;

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

            final peakWorkouts = timeframeWorkouts
                .where((w) => w.workoutTypeId == 2)
                .toList();

            if (peakWorkouts.isEmpty) {
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

            // ZOOM BOUNDARIES
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

            // AGGREGATE MAX PULLS
            Map<int, double> maxLeftPerBucket = {};
            Map<int, double> maxRightPerBucket = {};

            for (final w in peakWorkouts) {
              int xIndex = 0;
              if (_selectedRange == '1W') {
                xIndex = w.dateDone.weekday - 1;
              } else if (_selectedRange == '1M') {
                xIndex = (w.dateDone.day - 1) ~/ 7;
                if (xIndex > 3) xIndex = 3;
              } else if (_selectedRange == 'YTD') {
                xIndex = w.dateDone.month - 1;
              } else {
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

              double sessionMaxLeft = 0;
              double sessionMaxRight = 0;
              for (final set in w.sets) {
                for (final rep in set.repetitions) {
                  if (rep.peakLoadLeft > sessionMaxLeft) {
                    sessionMaxLeft = rep.peakLoadLeft;
                  }
                  if (rep.peakLoadRight > sessionMaxRight) {
                    sessionMaxRight = rep.peakLoadRight;
                  }
                }
              }

              if (sessionMaxLeft > (maxLeftPerBucket[xIndex] ?? 0)) {
                maxLeftPerBucket[xIndex] = sessionMaxLeft;
              }
              if (sessionMaxRight > (maxRightPerBucket[xIndex] ?? 0)) {
                maxRightPerBucket[xIndex] = sessionMaxRight;
              }
            }

            List<FlSpot> leftSpots = [];
            List<FlSpot> rightSpots = [];
            for (int i = 0; i <= maxX.toInt(); i++) {
              if (maxLeftPerBucket.containsKey(i)) {
                leftSpots.add(FlSpot(i.toDouble(), maxLeftPerBucket[i]!));
              }
              if (maxRightPerBucket.containsKey(i)) {
                rightSpots.add(FlSpot(i.toDouble(), maxRightPerBucket[i]!));
              }
            }

            // Y-AXIS MATH
            double absoluteMax = 10.0;
            if (leftSpots.isNotEmpty || rightSpots.isNotEmpty) {
              double maxL = leftSpots.isEmpty
                  ? 0
                  : leftSpots.map((e) => e.y).reduce(max);
              double maxR = rightSpots.isEmpty
                  ? 0
                  : rightSpots.map((e) => e.y).reduce(max);
              absoluteMax = max(maxL, maxR);
            }

            double maxWeight = 4.0;
            if (absoluteMax > 0) {
              double target = absoluteMax + (absoluteMax * 0.15);
              maxWeight = (target / 4).ceil() * 4.0;
            }
            double yInterval = maxWeight / 4;

            // DELEGATE TO BASE CHART!
            return BaseProgressionChart(
              maxX: maxX,
              maxY: maxWeight,
              yInterval: yInterval,

              lineBarsData: [
                BaseProgressionChart.createStandardLine(
                  spots: leftSpots,
                  color: leftColor,
                  cardBackgroundColor: context.cardBackground,
                ),
                BaseProgressionChart.createStandardLine(
                  spots: rightSpots,
                  color: rightColor,
                  cardBackgroundColor: context.cardBackground,
                ),
              ],

              // Custom Labels
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

              // Dynamic Tooltips
              tooltipBuilder: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final isLeft = spot.barIndex == 0;
                  final lineColor = isLeft ? leftColor : rightColor;
                  final label = _getTooltipLabel(spot.x, _selectedRange);

                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} kg ${isLeft ? "L" : "R"}',
                    TextStyle(color: lineColor, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left,
                    children: [
                      // Only show the date under the last touched spot to prevent duplicates
                      if (spot == touchedSpots.last)
                        TextSpan(
                          text: '\n$label',
                          style: TextStyle(
                            color: context.textPrimaryInv.withValues(
                              alpha: 0.8,
                            ),
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

        // Range Selector State
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
