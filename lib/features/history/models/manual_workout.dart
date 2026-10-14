import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/workouts/models/grip.dart';

/// One set of a workout entered by hand. Every rep is logged at the same
/// load, since there's no scale data to say otherwise.
class ManualSet {
  final int reps;
  final double loadLeftKg;
  final double loadRightKg;

  const ManualSet({this.reps = 1, this.loadLeftKg = 0, this.loadRightKg = 0});

  bool get hasLoad => loadLeftKg > 0 || loadRightKg > 0;

  /// [set] as it would have been entered by hand, or null if it holds more
  /// than the form can show: different loads per rep, averages that differ
  /// from the peaks, or a custom workout block, as sets from the scale do.
  static ManualSet? fromSetLog(SetLog set) {
    final reps = set.repetitions;
    if (reps.isEmpty || set.isWarmup || set.blockName != null) return null;

    final first = reps.first;
    final sameEverywhere = reps.every(
      (r) =>
          r.peakLoadLeft == first.peakLoadLeft &&
          r.peakLoadRight == first.peakLoadRight &&
          r.averageLoadLeft == first.peakLoadLeft &&
          r.averageLoadRight == first.peakLoadRight,
    );
    if (!sameEverywhere) return null;

    return ManualSet(
      reps: reps.length,
      loadLeftKg: first.peakLoadLeft,
      loadRightKg: first.peakLoadRight,
    );
  }

  ManualSet copyWith({int? reps, double? loadLeftKg, double? loadRightKg}) {
    return ManualSet(
      reps: reps ?? this.reps,
      loadLeftKg: loadLeftKg ?? this.loadLeftKg,
      loadRightKg: loadRightKg ?? this.loadRightKg,
    );
  }
}

/// The sets of [log] in hand-entered form, or null if any of them can't be
/// edited that way (see [ManualSet.fromSetLog]). A workout with a recorded
/// graph came from the scale, so it's never treated as hand-entered.
List<ManualSet>? manualSetsOf(WorkoutLog log) {
  if (log.graphData != null && log.graphData!.isNotEmpty) return null;
  if (log.sets.isEmpty) return null;

  final sets = <ManualSet>[];
  for (final s in log.sets) {
    final manual = ManualSet.fromSetLog(s);
    if (manual == null) return null;
    sets.add(manual);
  }
  return sets;
}

/// Turns a hand-entered workout into a [WorkoutLog] ready to save.
///
/// [name] is only used for [WorkoutId.custom], where it's stored as the
/// template name so history has something to show. Sets without any load
/// are dropped.
WorkoutLog buildManualWorkout({
  required int workoutTypeId,
  required DateTime dateDone,
  required int durationSeconds,
  required List<ManualSet> sets,
  GripSetup grip = GripSetup.none,
  String notes = '',
  String? name,
}) {
  final trimmedName = name?.trim();
  final isCustom = workoutTypeId == WorkoutId.custom;

  return WorkoutLog(
    workoutTypeId: workoutTypeId,
    dateDone: dateDone,
    duration: durationSeconds,
    // Not known without the scale, so don't guess.
    workingTime: 0,
    notes: notes.trim(),
    graphData: null,
    templateName: isCustom && trimmedName != null && trimmedName.isNotEmpty
        ? trimmedName
        : null,
    sets: [
      for (final s in sets)
        if (s.hasLoad && s.reps > 0)
          SetLog(
            grip: grip,
            repetitions: [
              for (var r = 0; r < s.reps; r++)
                RepetitionLog(
                  peakLoadLeft: s.loadLeftKg,
                  peakLoadRight: s.loadRightKg,
                  averageLoadLeft: s.loadLeftKg,
                  averageLoadRight: s.loadRightKg,
                ),
            ],
          ),
    ],
  );
}
