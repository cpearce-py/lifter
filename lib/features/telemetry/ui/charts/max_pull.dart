import 'package:lifter/features/history/models/log_models.dart';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/telemetry/providers/chart_workout_provider.dart';
import 'package:lifter/features/telemetry/providers/grip_filter_provider.dart';
import 'package:lifter/features/telemetry/ui/charts/base_chart.dart';
import 'package:lifter/features/telemetry/ui/widgets/range_selector.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';
import '../helpers.dart';

/// Best load per hand over time, from the working sets of [workoutTypeIds]
/// that match the Progression page's grip filter.
class MaxPullProgressionChart extends ConsumerStatefulWidget {
  const MaxPullProgressionChart({
    super.key,
    this.workoutTypeIds = const {WorkoutId.peakLoad},
    this.useAverage = false,
    this.emptyMessage = 'Complete a Peak Load to see progress',
  });

  final Set<int> workoutTypeIds;

  /// Chart each rep's average load rather than its peak.
  final bool useAverage;
  final String emptyMessage;

  @override
  ConsumerState<MaxPullProgressionChart> createState() =>
      _MaxPullProgressionChartState();
}

class _MaxPullProgressionChartState
    extends ConsumerState<MaxPullProgressionChart> {
  TimeRange _selectedRange = TimeRange.year;

  @override
  Widget build(BuildContext context) {
    final chartDataAsync = ref.watch(chartWorkoutsProvider);
    final useLbs = ref.watch(userSettingsProvider.select((s) => s.useLbs));
    final gripFilter = ref.watch(gripFilterProvider);

    final leftColor = context.leftHandAccent;
    final rightColor = context.rightHandAccent;

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
            final range = _selectedRange;

            // Best load per hand in each bucket, already in the display unit
            // so the y-axis snaps to round kg or lbs values.
            final maxLeftPerBucket = <int, double>{};
            final maxRightPerBucket = <int, double>{};

            for (final w in allWorkouts) {
              if (!widget.workoutTypeIds.contains(w.workoutTypeId)) continue;
              final index = range.bucketOf(w.dateDone, now);
              if (index == null) continue;
              final best = bestLoadOnGrip(
                w,
                gripFilter,
                useAverage: widget.useAverage,
              );
              if (best == null) continue;

              final left = displayWeight(best.left, useLbs);
              final right = displayWeight(best.right, useLbs);
              if (left > (maxLeftPerBucket[index] ?? 0)) {
                maxLeftPerBucket[index] = left;
              }
              if (right > (maxRightPerBucket[index] ?? 0)) {
                maxRightPerBucket[index] = right;
              }
            }

            if (maxLeftPerBucket.isEmpty && maxRightPerBucket.isEmpty) {
              return SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    gripFilter.isAll
                        ? widget.emptyMessage
                        : 'Nothing logged on this grip yet',
                    textAlign: TextAlign.center,
                    style: context.body.copyWith(color: context.textMuted),
                  ),
                ),
              );
            }

            List<FlSpot> toSpots(Map<int, double> buckets) => [
              for (final index in buckets.keys.toList()..sort())
                FlSpot(index.toDouble(), buckets[index]!),
            ];
            final leftSpots = toSpots(maxLeftPerBucket);
            final rightSpots = toSpots(maxRightPerBucket);

            final maxWeight = niceMax(
              [...maxLeftPerBucket.values, ...maxRightPerBucket.values]
                  .reduce(max),
              4,
            );

            return BaseProgressionChart(
              maxX: range.maxX(now),
              maxY: maxWeight,
              yInterval: maxWeight / 4,

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

              bottomLabelBuilder: (value) => Text(
                range.axisLabel(value.toInt(), now),
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

              tooltipBuilder: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final isLeft = spot.barIndex == 0;
                  final lineColor = isLeft ? leftColor : rightColor;

                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} ${weightUnit(useLbs)} ${isLeft ? "L" : "R"}',
                    TextStyle(color: lineColor, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left,
                    children: [
                      // Only show the date under the last touched spot to prevent duplicates
                      if (spot == touchedSpots.last)
                        TextSpan(
                          text:
                              '\n${range.tooltipLabel(spot.x.toInt(), now)}',
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

        RangeSelector(
          selected: _selectedRange,
          onChanged: (range) => setState(() => _selectedRange = range),
        ),
      ],
    );
  }
}
