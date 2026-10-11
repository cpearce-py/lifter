import 'dart:math';
import 'dart:typed_data';

import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/ui/workout_theme_extension.dart';
import 'package:lifter/features/workouts/models/grip.dart';

//TODO: delete after testing.

const _crimp20 = GripSetup(grip: GripType.halfCrimp, edgeMm: 20);
const _crimp15 = GripSetup(grip: GripType.halfCrimp, edgeMm: 15);
const _crimp10 = GripSetup(grip: GripType.halfCrimp, edgeMm: 10);
const _open20 = GripSetup(grip: GripType.openHand, edgeMm: 20);
const _open15 = GripSetup(grip: GripType.openHand, edgeMm: 15);
const _drag20 = GripSetup(grip: GripType.threeFingerDrag, edgeMm: 20);
const _pinch = GripSetup(grip: GripType.pinch);

typedef _Block = ({
  String name,
  bool warmup,
  GripSetup grip,
  int sets,
  int reps,
  double pct,
});

/// Workouts older than this many days have no grip, like history logged
/// before grips could be recorded.
const _gripsSinceDays = 300;

/// Roughly a year of training for exercising the History and Progression
/// screens: Peak Loads every two weeks, Repeaters weekly and custom
/// workouts every ten days, rotating through grips and edges, with loads
/// that climb over the year. Uses a fixed random seed, so only the dates
/// depend on [now].
List<WorkoutLog> dummyWorkouts(DateTime now) {
  final random = Random(42);
  final emptyBlob = Uint8List(0);
  final workouts = <WorkoutLog>[];

  // Wobbles a load by up to ±[spread] kg, rounded to 0.1 kg.
  double noisy(double kg, [double spread = 1.0]) =>
      ((kg + (random.nextDouble() * 2 - 1) * spread) * 10).round() / 10;

  // How far through the year a workout [daysAgo] is, 0 → 1.
  double progress(int daysAgo) => 1 - daysAgo / 365;

  // Peak load per grip at the start of the year.
  final baselines = {
    _open20: 26.0,
    _crimp20: 24.0,
    _crimp15: 21.0,
    _crimp10: 18.0,
    _drag20: 25.0,
    _open15: 22.0,
    _pinch: 14.0,
  };

  RepetitionLog rep(double left, double right, {double avgRatio = 0.88}) {
    return RepetitionLog(
      peakLoadLeft: left,
      peakLoadRight: right,
      averageLoadLeft: (left * avgRatio * 10).round() / 10,
      averageLoadRight: (right * avgRatio * 10).round() / 10,
    );
  }

  // Strength on [grip] [daysAgo] days ago, with the right hand a touch
  // stronger, as most people's is.
  ({double left, double right}) strength(GripSetup grip, int daysAgo) {
    final kg = baselines[grip]! * (1 + 0.3 * progress(daysAgo));
    return (left: noisy(kg), right: noisy(kg + 0.8));
  }

  DateTime dateFor(int daysAgo) =>
      now.subtract(Duration(days: daysAgo, hours: daysAgo == 0 ? 1 : 0));

  GripSetup tagged(GripSetup grip, int daysAgo) =>
      daysAgo > _gripsSinceDays ? GripSetup.none : grip;

  // --- Peak Loads: every 14 days, rotating three test edges ---
  const peakGrips = [_crimp20, _open20, _crimp10];
  for (var i = 0, d = 0; d <= 365; i++, d += 14) {
    final grip = peakGrips[i % peakGrips.length];
    final s = strength(grip, d);

    // A few attempts building up to the best one.
    workouts.add(WorkoutLog(
      workoutTypeId: WorkoutId.peakLoad,
      dateDone: dateFor(d),
      duration: 600,
      workingTime: 42,
      notes: i == 0 ? 'New best on the ${grip.label}!' : '',
      graphData: emptyBlob,
      sets: [
        for (final pct in [0.85, 0.95, 1.0])
          SetLog(
            repetitions: [rep(noisy(s.left * pct, 0.3), noisy(s.right * pct, 0.3))],
            grip: tagged(grip, d),
          ),
      ],
    ));
  }

  // --- Repeaters: weekly, rotating three grips, 3 sets of 6 reps ---
  const repeaterGrips = [_open20, _crimp20, _drag20];
  for (var i = 0, d = 1; d <= 365; i++, d += 7) {
    final grip = repeaterGrips[i % repeaterGrips.length];
    final s = strength(grip, d);

    workouts.add(WorkoutLog(
      workoutTypeId: WorkoutId.repeater,
      dateDone: dateFor(d),
      duration: 540,
      workingTime: 252,
      notes: i % 5 == 0 ? 'Skin was thin, but got through the sets.' : '',
      graphData: emptyBlob,
      sets: [
        for (var set = 0; set < 3; set++)
          SetLog(
            grip: tagged(grip, d),
            repetitions: [
              // ~60% of max, fading a little each rep and each set.
              for (var r = 0; r < 6; r++)
                rep(
                  noisy(s.left * (0.62 - 0.01 * r - 0.02 * set), 0.4),
                  noisy(s.right * (0.62 - 0.01 * r - 0.02 * set), 0.4),
                  avgRatio: 0.92,
                ),
            ],
          ),
      ],
    ));
  }

  // One set of a custom block, [set] sets in. Warm-ups ramp up as they go.
  SetLog blockSet(_Block block, int blockIndex, int set, int daysAgo) {
    final s = strength(block.grip, daysAgo);
    final pct = block.warmup ? block.pct + 0.1 * set : block.pct;
    return SetLog(
      isWarmup: block.warmup,
      blockName: block.name,
      blockIndex: blockIndex,
      grip: tagged(block.grip, daysAgo),
      repetitions: [
        for (var r = 0; r < block.reps; r++)
          rep(noisy(s.left * pct, 0.4), noisy(s.right * pct, 0.4), avgRatio: 0.9),
      ],
    );
  }

  // --- Custom workouts: every 10 days, alternating two templates ---
  for (var i = 0, d = 3; d <= 365; i++, d += 10) {
    final List<_Block> blocks;
    final String templateName;

    if (i.isEven) {
      templateName = 'Max Hangs';
      blocks = [
        (name: 'Warm-up', warmup: true, grip: _open20, sets: 3, reps: 2, pct: 0.5),
        (name: 'Max hangs', warmup: false, grip: _crimp10, sets: 5, reps: 1, pct: 0.92),
      ];
    } else {
      templateName = 'Grip Circuit';
      blocks = [
        (name: 'Warm-up', warmup: true, grip: _open20, sets: 2, reps: 3, pct: 0.45),
        (name: 'Half crimp', warmup: false, grip: _crimp15, sets: 3, reps: 3, pct: 0.75),
        (name: 'Open hand', warmup: false, grip: _open15, sets: 3, reps: 3, pct: 0.75),
        (name: 'Pinch', warmup: false, grip: _pinch, sets: 2, reps: 3, pct: 0.8),
      ];
    }

    workouts.add(WorkoutLog(
      workoutTypeId: WorkoutId.custom,
      dateDone: dateFor(d),
      duration: 1500,
      workingTime: 200,
      notes: i == 0 ? 'Warm-up felt good, last max hang was a fight.' : '',
      graphData: emptyBlob,
      templateName: templateName,
      sets: [
        for (var b = 0; b < blocks.length; b++)
          for (var set = 0; set < blocks[b].sets; set++)
            blockSet(blocks[b], b, set, d),
      ],
    ));
  }

  workouts.sort((a, b) => a.dateDone.compareTo(b.dateDone));
  return workouts;
}
