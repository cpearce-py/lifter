import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/workouts/models/grip.dart';

/// The grip and edge the Progression charts are narrowed to.
final gripFilterProvider = NotifierProvider<GripFilterNotifier, GripFilter>(
  GripFilterNotifier.new,
);

class GripFilterNotifier extends Notifier<GripFilter> {
  @override
  GripFilter build() => GripFilter.all;

  void setGrip(GripType? grip) => state = state.withGrip(grip);
  void setEdge(int? edgeMm) => state = state.withEdge(edgeMm);
}

/// Best load per hand across a workout's working sets that match [filter].
/// Uses each rep's peak, or its average when [useAverage] is set. Null when
/// no working set matches.
({double left, double right})? bestLoadOnGrip(
  WorkoutLog workout,
  GripFilter filter, {
  bool useAverage = false,
}) {
  double? left;
  double? right;

  for (final set in workout.sets) {
    if (set.isWarmup || !filter.matches(set.grip)) continue;
    for (final rep in set.repetitions) {
      final l = useAverage ? rep.averageLoadLeft : rep.peakLoadLeft;
      final r = useAverage ? rep.averageLoadRight : rep.peakLoadRight;
      left = max(left ?? 0, l);
      right = max(right ?? 0, r);
    }
  }

  if (left == null || right == null) return null;
  return (left: left, right: right);
}

/// Every grip and edge that appears in [workouts], for the filter dropdowns.
({List<GripType> grips, List<int> edges}) loggedGrips(
  Iterable<WorkoutLog> workouts,
) {
  final grips = <GripType>{};
  final edges = <int>{};
  for (final w in workouts) {
    for (final s in w.sets) {
      if (s.grip.grip != null) grips.add(s.grip.grip!);
      if (s.grip.edgeMm != null) edges.add(s.grip.edgeMm!);
    }
  }
  return (
    grips: grips.toList()..sort((a, b) => a.index.compareTo(b.index)),
    edges: edges.toList()..sort(),
  );
}
