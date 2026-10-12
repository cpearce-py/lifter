import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/telemetry/providers/chart_workout_provider.dart';
import 'package:lifter/features/telemetry/ui/charts/base_chart.dart';
import 'package:lifter/features/telemetry/ui/widgets/range_selector.dart';
import '../helpers.dart';

class WorkoutsProgressionChart extends ConsumerStatefulWidget {
  const WorkoutsProgressionChart({super.key});

  @override
  ConsumerState<WorkoutsProgressionChart> createState() =>
      _WorkoutsProgressionChartState();
}

class _WorkoutsProgressionChartState
    extends ConsumerState<WorkoutsProgressionChart> {
  TimeRange _selectedRange = TimeRange.year;

  @override
  Widget build(BuildContext context) {
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
            final range = _selectedRange;

            // Count workouts per bucket.
            final counts = <int, int>{};
            for (final w in allWorkouts) {
              final index = range.bucketOf(w.dateDone, now);
              if (index != null) counts[index] = (counts[index] ?? 0) + 1;
            }

            // Empty buckets get a 0 so the line drops to the floor, but stop
            // at the current bucket so days/weeks still to come aren't drawn
            // as a decline.
            final spots = [
              for (int i = 0; i <= range.currentIndex(now); i++)
                FlSpot(i.toDouble(), (counts[i] ?? 0).toDouble()),
            ];

            // Snap to multiples of 3 for 4 whole-number grid lines.
            final highest = counts.values.fold(0, (a, b) => a > b ? a : b);
            final maxWorkouts = niceMax(highest.toDouble(), 3);

            return BaseProgressionChart(
              maxX: range.maxX(now),
              maxY: maxWorkouts,
              yInterval: maxWorkouts / 3,

              lineBarsData: [
                BaseProgressionChart.createStandardLine(
                  spots: spots,
                  color: context.streakAccent,
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
                  final count = spot.y.toInt();
                  return LineTooltipItem(
                    '$count ${count == 1 ? 'workout' : 'workouts'}',
                    TextStyle(
                      color: context.textPrimaryInv,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.left,
                    children: [
                      TextSpan(
                        text: '\n${range.tooltipLabel(spot.x.toInt(), now)}',
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

        RangeSelector(
          selected: _selectedRange,
          onChanged: (range) => setState(() => _selectedRange = range),
        ),
      ],
    );
  }
}
