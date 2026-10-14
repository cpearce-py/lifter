import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/models/manual_workout.dart';
import 'package:lifter/features/workouts/models/grip.dart';

void main() {
  final date = DateTime(2026, 10, 1, 18, 30);
  const crimp20 = GripSetup(grip: GripType.halfCrimp, edgeMm: 20);

  test('expands each set into reps at the entered load', () {
    final log = buildManualWorkout(
      workoutTypeId: WorkoutId.repeater,
      dateDone: date,
      durationSeconds: 1800,
      sets: const [
        ManualSet(reps: 3, loadLeftKg: 20, loadRightKg: 22),
        ManualSet(reps: 2, loadLeftKg: 18, loadRightKg: 18),
      ],
      grip: crimp20,
      notes: '  felt strong ',
    );

    expect(log.workoutTypeId, WorkoutId.repeater);
    expect(log.dateDone, date);
    expect(log.duration, 1800);
    expect(log.notes, 'felt strong');
    expect(log.graphData, isNull);
    expect(log.sets.map((s) => s.repetitions.length), [3, 2]);
    expect(log.sets.first.repetitions.first.peakLoadLeft, 20);
    expect(log.sets.first.repetitions.first.peakLoadRight, 22);
    expect(log.sets.first.repetitions.first.averageLoadRight, 22);
    expect(log.grips, [crimp20]);
  });

  test('drops sets with no load', () {
    final log = buildManualWorkout(
      workoutTypeId: WorkoutId.peakLoad,
      dateDone: date,
      durationSeconds: 600,
      sets: const [ManualSet(reps: 1), ManualSet(reps: 1, loadLeftKg: 40)],
    );

    expect(log.sets, hasLength(1));
    expect(log.sets.single.repetitions.single.peakLoadLeft, 40);
  });

  test('only custom workouts keep a name', () {
    String? nameFor(int type, String name) => buildManualWorkout(
          workoutTypeId: type,
          dateDone: date,
          durationSeconds: 60,
          sets: const [],
          name: name,
        ).templateName;

    expect(nameFor(WorkoutId.custom, ' Max hangs '), 'Max hangs');
    expect(nameFor(WorkoutId.custom, '  '), isNull);
    expect(nameFor(WorkoutId.repeater, 'Max hangs'), isNull);
  });

  group('editing', () {
    RepetitionLog repAt(double l, double r, {double? avg}) => RepetitionLog(
          peakLoadLeft: l,
          peakLoadRight: r,
          averageLoadLeft: avg ?? l,
          averageLoadRight: avg ?? r,
        );

    test('hand-entered sets come back as they were entered', () {
      final log = buildManualWorkout(
        workoutTypeId: WorkoutId.repeater,
        dateDone: date,
        durationSeconds: 60,
        sets: const [ManualSet(reps: 4, loadLeftKg: 20, loadRightKg: 22)],
      );

      final sets = manualSetsOf(log)!;
      expect(sets.single.reps, 4);
      expect(sets.single.loadLeftKg, 20);
      expect(sets.single.loadRightKg, 22);
    });

    test('sets from the scale are not treated as hand-entered', () {
      final base = buildManualWorkout(
        workoutTypeId: WorkoutId.repeater,
        dateDone: date,
        durationSeconds: 60,
        sets: const [ManualSet(reps: 2, loadLeftKg: 20, loadRightKg: 20)],
      );

      // Different loads per rep.
      expect(
        manualSetsOf(base.copyWith(sets: [
          SetLog(repetitions: [repAt(20, 20), repAt(21, 20)]),
        ])),
        isNull,
      );
      // Averages below the peaks.
      expect(
        manualSetsOf(base.copyWith(sets: [
          SetLog(repetitions: [repAt(40, 40, avg: 35)]),
        ])),
        isNull,
      );
      // Part of a custom workout block.
      expect(
        manualSetsOf(base.copyWith(sets: [
          SetLog(repetitions: [repAt(20, 20)], blockName: 'Max hangs'),
        ])),
        isNull,
      );
      // Has a recorded graph.
      expect(manualSetsOf(base.copyWith(graphData: Uint8List(4))), isNull);
    });
  });
}
