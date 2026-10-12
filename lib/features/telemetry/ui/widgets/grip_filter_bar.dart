import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/core/ui/widgets/controls.dart';
import 'package:lifter/features/telemetry/providers/chart_workout_provider.dart';
import 'package:lifter/features/telemetry/providers/grip_filter_provider.dart';

/// Narrows the load charts below it to one grip and/or edge. Only offers
/// what has actually been logged, plus whatever is already selected.
class GripFilterBar extends ConsumerWidget {
  const GripFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(gripFilterProvider);
    final notifier = ref.read(gripFilterProvider.notifier);
    final workouts = ref.watch(chartWorkoutsProvider).value ?? const [];

    final logged = loggedGrips(workouts);
    final grips = {...logged.grips, ?filter.grip}.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final edges = {...logged.edges, ?filter.edgeMm}.toList()..sort();

    final accent = context.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Grip & Edge',
                  style: context.h1.copyWith(fontSize: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            grips.isEmpty && edges.isEmpty
                ? 'Set a grip or edge when starting a workout to compare them here'
                : 'Filters the load charts below',
            style: context.body.copyWith(color: context.textMuted),
          ),
          if (grips.isNotEmpty || edges.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Grip', style: context.body),
                DropdownControl(
                  choices: ['All grips', ...grips.map((g) => g.label)],
                  selectedIndex:
                      filter.grip == null ? 0 : grips.indexOf(filter.grip!) + 1,
                  accentColor: accent,
                  onChanged: (i) =>
                      notifier.setGrip(i == 0 ? null : grips[i - 1]),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: context.cardBorder, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Edge', style: context.body),
                DropdownControl(
                  choices: ['All edges', ...edges.map((mm) => '$mm mm')],
                  selectedIndex: filter.edgeMm == null
                      ? 0
                      : edges.indexOf(filter.edgeMm!) + 1,
                  accentColor: accent,
                  onChanged: (i) =>
                      notifier.setEdge(i == 0 ? null : edges[i - 1]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
