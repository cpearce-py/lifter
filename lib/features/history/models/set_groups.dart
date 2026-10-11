import 'dart:math';

import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/workouts/models/grip.dart';

/// A run of consecutive sets that share a block and grip, e.g. the five
/// sets of "Max hangs" on 10mm half crimp. Lets the detail page say the
/// block's name and grip once instead of on every set.
class SetGroup {
  /// The block's name for custom workouts, otherwise null.
  final String? name;
  final GripSetup grip;
  final bool isWarmup;
  final List<SetLog> sets;

  const SetGroup({
    required this.name,
    required this.grip,
    required this.isWarmup,
    required this.sets,
  });

  int get repCount => sets.fold(0, (sum, s) => sum + s.repetitions.length);

  /// Best peak per hand across the group's reps.
  ({double left, double right}) get best {
    var left = 0.0;
    var right = 0.0;
    for (final set in sets) {
      for (final rep in set.repetitions) {
        left = max(left, rep.peakLoadLeft);
        right = max(right, rep.peakLoadRight);
      }
    }
    return (left: left, right: right);
  }
}

/// The warm-up or working half of a workout.
class SetPhase {
  final bool isWarmup;
  final List<SetGroup> groups;

  const SetPhase({required this.isWarmup, required this.groups});
}

/// Splits [sets] into groups of consecutive sets from the same block on
/// the same grip, keeping their order.
List<SetGroup> groupSets(List<SetLog> sets) {
  final groups = <SetGroup>[];

  for (final set in sets) {
    final last = groups.isEmpty ? null : groups.last;
    final sameGroup = last != null &&
        last.sets.last.blockIndex == set.blockIndex &&
        last.name == set.blockName &&
        last.grip == set.grip &&
        last.isWarmup == set.isWarmup;

    if (sameGroup) {
      last.sets.add(set);
    } else {
      groups.add(SetGroup(
        name: set.blockName,
        grip: set.grip,
        isWarmup: set.isWarmup,
        sets: [set],
      ));
    }
  }

  return groups;
}

/// Groups [sets] (see [groupSets]) under warm-up and working phases, each
/// in the order it first appears. A workout without warm-ups has a single
/// working phase.
List<SetPhase> phaseSets(List<SetLog> sets) {
  final groups = groupSets(sets);
  return [
    for (final warmup in [true, false])
      if (groups.any((g) => g.isWarmup == warmup))
        SetPhase(
          isWarmup: warmup,
          groups: groups.where((g) => g.isWarmup == warmup).toList(),
        ),
  ];
}
