import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import 'package:lifter/features/telemetry/models.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/telemetry/ui/charts/base_chart.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';
import '../helpers.dart';

class RepProgressionChart extends ConsumerWidget {
  final WorkoutStats stats;

  const RepProgressionChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leftColor = context.repeaterAccent;
    final rightColor = context.setRestAccent;
    final useLbs = ref.watch(userSettingsProvider.select((s) => s.useLbs));

    // 1. If there's no data, show a friendly empty state
    if (stats.flatReps.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'No repetition data available',
            style: context.body.copyWith(color: context.textMuted),
          ),
        ),
      );
    }

    // 2. Generate the spots (X = Rep Number, Y = Peak Load)
    List<FlSpot> leftSpots = [];
    List<FlSpot> rightSpots = [];

    for (int i = 0; i < stats.flatReps.length; i++) {
      leftSpots.add(FlSpot(i.toDouble(), stats.flatReps[i].peakLoadLeft));
      rightSpots.add(FlSpot(i.toDouble(), stats.flatReps[i].peakLoadRight));
    }

    // 3. X-Axis Math: Limit the chart to exactly the number of reps
    double maxX = (stats.flatReps.length - 1).toDouble();
    if (maxX <= 0) maxX = 1.0; // Safety fallback if only 1 rep exists

    // 4. Y-Axis Math: Add 15% headroom above the absolute max, snap to multiples of 4
    double absoluteMax = max(stats.maxLeft, stats.maxRight);
    double maxWeight = 4.0;
    if (absoluteMax > 0) {
      double target = absoluteMax + (absoluteMax * 0.15);
      maxWeight = (target / 4).ceil() * 4.0;
    }
    double yInterval = maxWeight / 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Fatigue Curve',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        BaseProgressionChart(
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

          // X-Axis Labels: Simple Rep Numbers (1, 2, 3...)
          bottomLabelBuilder: (value) => Text(
            (value.toInt() + 1)
                .toString(),
            style: context.overline.copyWith(color: context.textMuted),
          ),

          // Y-Axis Labels: Weight
          leftLabelBuilder: (value) => Text(
            displayWeight(value, useLbs).toInt().toString(),
            style: context.overline.copyWith(
              color: context.textMuted,
              fontWeight: FontWeight.normal,
            ),
            textAlign: TextAlign.right,
          ),

          // Custom Dynamic Tooltips
          tooltipBuilder: (touchedSpots) {
            return touchedSpots.map((spot) {
              final isLeft = spot.barIndex == 0;
              final lineColor = isLeft ? leftColor : rightColor;
              final displayValue = displayWeight(
                spot.y,
                useLbs,
              ).toStringAsFixed(1);
              final leftOrRight = isLeft ? "L" : "R";

              return LineTooltipItem(
                '$displayValue ${weightUnit(useLbs)} $leftOrRight',
                TextStyle(color: lineColor, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
                children: [
                  // Only show the "Rep #" string on the bottom item to avoid duplication
                  if (spot == touchedSpots.last)
                    TextSpan(
                      text: '\nRep ${spot.x.toInt() + 1}',
                      style: context.overline.copyWith(
                        color: context.background.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                ],
              );
            }).toList();
          },
        ),
      ],
    );
  }
}
