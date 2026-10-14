import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/repositories/dummy_workouts.dart';
import 'package:lifter/features/telemetry/providers/grip_filter_provider.dart';
import 'package:lifter/features/workouts/models/grip.dart';

RepetitionLog rep(double left, double right) => RepetitionLog(
      peakLoadLeft: left,
      peakLoadRight: right,
      averageLoadLeft: left - 5,
      averageLoadRight: right - 5,
    );

const crimp20 = GripSetup(grip: GripType.halfCrimp, edgeMm: 20);
const open20 = GripSetup(grip: GripType.openHand, edgeMm: 20);
const crimp10 = GripSetup(grip: GripType.halfCrimp, edgeMm: 10);

final workout = WorkoutLog(
  workoutTypeId: 3,
  dateDone: DateTime(2026, 10, 1),
  duration: 600,
  workingTime: 100,
  graphData: Uint8List(0),
  sets: [
    SetLog(repetitions: [rep(50, 50)], isWarmup: true, grip: crimp20),
    SetLog(repetitions: [rep(30, 32), rep(31, 29)], grip: crimp20),
    SetLog(repetitions: [rep(40, 41)], grip: open20),
    SetLog(repetitions: [rep(20, 22)], grip: crimp10),
  ],
);

void main() {
  test('a filter half left null matches anything', () {
    expect(GripFilter.all.matches(GripSetup.none), isTrue);
    expect(const GripFilter(edgeMm: 20).matches(crimp20), isTrue);
    expect(const GripFilter(edgeMm: 20).matches(crimp10), isFalse);
    expect(const GripFilter(grip: GripType.halfCrimp).matches(crimp10), isTrue);
    expect(const GripFilter(grip: GripType.halfCrimp).matches(GripSetup.none),
        isFalse);
  });

  test('best load only counts matching working sets', () {
    final all = bestLoadOnGrip(workout, GripFilter.all)!;
    expect((all.left, all.right), (40, 41)); // warm-up's 50 is ignored

    final crimp = bestLoadOnGrip(
        workout, const GripFilter(grip: GripType.halfCrimp, edgeMm: 20))!;
    expect((crimp.left, crimp.right), (31, 32));

    final avg = bestLoadOnGrip(workout, const GripFilter(edgeMm: 10),
        useAverage: true)!;
    expect((avg.left, avg.right), (15, 17));

    expect(bestLoadOnGrip(workout, const GripFilter(grip: GripType.pinch)),
        isNull);
  });

  test('lists the grips and edges that were logged, in order', () {
    final logged = loggedGrips([workout]);
    expect(logged.grips, [GripType.halfCrimp, GripType.openHand]);
    expect(logged.edges, [10, 20]);
  });

  test('withGrip tags every set but leaves untagged logs alone', () {
    expect(workout.withGrip(GripSetup.none), same(workout));
    expect(workout.withGrip(open20).sets.map((s) => s.grip).toSet(), {open20});
  });

  test('grips lists each distinct grip in first-used order', () {
    expect(workout.grips, [crimp20, open20, crimp10]);
  });

  group('dummy seed', () {
    final now = DateTime(2026, 10, 11, 12);
    final seeded = dummyWorkouts(now);

    test('covers every workout type across the year, including this week', () {
      expect(seeded.map((w) => w.workoutTypeId).toSet(),
          {WorkoutId.repeater, WorkoutId.peakLoad, WorkoutId.custom});
      expect(seeded.first.dateDone.isBefore(now.subtract(const Duration(days: 330))), isTrue);
      expect(seeded.where((w) => now.difference(w.dateDone).inDays < 7).length,
          greaterThanOrEqualTo(3));
    });

    test('gives the grip filter several grips and edges to choose from', () {
      final logged = loggedGrips(seeded);
      expect(logged.grips.length, greaterThanOrEqualTo(4));
      expect(logged.edges, [10, 15, 20]);
    });

    test('has older workouts with no grip, like pre-grip history', () {
      expect(seeded.where((w) => w.grips.isEmpty), isNotEmpty);
    });

    test('has custom workouts that mix grips across blocks', () {
      expect(
        seeded.where((w) => w.workoutTypeId == WorkoutId.custom && w.grips.length > 1),
        isNotEmpty,
      );
    });

    test('Peak Load strength climbs on the same grip', () {
      const filter = GripFilter(grip: GripType.halfCrimp, edgeMm: 20);
      final bests = [
        for (final w in seeded)
          if (w.workoutTypeId == WorkoutId.peakLoad)
            if (bestLoadOnGrip(w, filter) case final best?) best.left,
      ];
      expect(bests.length, greaterThan(3));
      expect(bests.last, greaterThan(bests.first));
    });
  });
}
