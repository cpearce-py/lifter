import 'package:flutter_test/flutter_test.dart';
import 'package:lifter/features/user/models/user_profile.dart';
import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/custom/custom_workout_state.dart';
import 'package:lifter/features/workouts/models/custom/workout_template.dart';
import 'package:lifter/features/workouts/models/intensity.dart';
import 'package:lifter/features/workouts/rules/custom_workout_rules.dart';

const settings = UserSettings(bodyWeight: 45, maxPullLeft: 40, maxPullRight: 50);

const warmup = WorkoutBlock(
  name: "Warm-up",
  kind: BlockKind.warmup,
  sets: 3,
  reps: 1,
  workSeconds: 3,
  restSeconds: 3,
  setRestSeconds: 10,
  restAfterSeconds: 30,
  relativeTo: RelativeTo.bodyweight,
  startPercentage: 30,
  endPercentage: 60,
);

const working = WorkoutBlock(
  name: "Max hangs",
  sets: 2,
  reps: 2,
  workSeconds: 3,
  restSeconds: 3,
  setRestSeconds: 10,
  relativeTo: RelativeTo.maxPull,
  startPercentage: 80,
  endPercentage: 80,
);

const template = WorkoutTemplate(
  id: 7,
  name: "Test",
  blocks: [warmup, working],
);

final rules = CustomWorkoutRules();

CustomWorkoutState initialState() {
  final steps = compileTemplate(template, settings);
  return CustomWorkoutState(
    templateId: template.id,
    templateName: template.name,
    steps: steps,
    inner: steps.first.seed,
  );
}

CustomWorkoutState send(CustomWorkoutState state, WorkoutAction action) =>
    rules.reduce(state, action);

/// Ticks (pulling 20kg each second) until [until] holds or the workout ends.
CustomWorkoutState runUntil(
  CustomWorkoutState state,
  bool Function(CustomWorkoutState) until,
) {
  for (var i = 0; i < 10000; i++) {
    if (until(state) || state.phase == Phase.done) return state;
    state = send(state, WeightReceivedAction(20));
    state = send(state, TickAction());
  }
  fail("Workout never reached the expected state");
}

void main() {
  group('compileTemplate', () {
    final steps = compileTemplate(template, settings);

    test('splits a ramped block into one step per set', () {
      expect(steps.length, 4);
      expect(steps.map((s) => s.percentage), [30, 45, 60, 80]);
      expect(steps.map((s) => s.blockIndex), [0, 0, 0, 1]);
      expect(steps.map((s) => s.setOffset), [0, 1, 2, 0]);
      expect(steps.take(3).every((s) => s.seed.sets == 1), isTrue);
    });

    test('keeps a flat block as a single step', () {
      expect(steps.last.seed.sets, 2);
      expect(steps.last.seed.reps, 2);
    });

    test('uses set rest inside a block and rest-after between blocks', () {
      expect(steps.map((s) => s.restBeforeSeconds), [0, 10, 10, 30]);
    });

    test('resolves targets against the chosen reference', () {
      expect(steps.first.targetWeight, closeTo(45 * 0.30, 0.001));
      expect(steps.last.targetWeight, closeTo(50 * 0.80, 0.001));
    });

    test('never leaves a zero-length rest between steps', () {
      const noRest = WorkoutTemplate(name: "x", blocks: [
        WorkoutBlock(name: "a", sets: 1, restAfterSeconds: 0),
        WorkoutBlock(name: "b", sets: 1),
      ]);
      final s = compileTemplate(noRest, settings);
      expect(s.last.restBeforeSeconds, minTransitionSeconds);
    });
  });

  group('CustomWorkoutRules', () {
    test('runs every block and tags the sets', () {
      var state = send(initialState(), UserEventAction(Event.start));
      state = runUntil(state, (_) => false);

      expect(state.phase, Phase.done);
      expect(state.completedSets.length, 5); // 3 warm-up + 2 working
      expect(state.completedSets.map((s) => s.isWarmup),
          [true, true, true, false, false]);
      expect(state.completedSets.map((s) => s.blockIndex), [0, 0, 0, 1, 1]);
      expect(state.completedSets.last.blockName, "Max hangs");
      expect(state.completedSets.last.repetitions.length, 2);
      expect(state.totalWorkSeconds, greaterThan(0));
    });

    test('rests between steps, then goes straight into work', () {
      var state = send(initialState(), UserEventAction(Event.start));
      state = runUntil(state, (s) => s.stepIndex == 1);

      expect(state.phase, Phase.setResting);
      expect(state.secondsRemainingForTest, 10);

      state = runUntil(state, (s) => s.phase == Phase.working);
      expect(state.stepIndex, 1);
      expect(state.blockSet, 2);
    });

    test('finish ends the whole workout, not just the step', () {
      var state = send(initialState(), UserEventAction(Event.start));
      state = runUntil(state, (s) => s.phase == Phase.working);
      state = send(state, WeightReceivedAction(25));
      state = send(state, UserEventAction(Event.finish));

      expect(state.phase, Phase.done);
      expect(state.stepIndex, 0);
      expect(state.completedSets.length, 1);
      expect(state.completedSets.first.isWarmup, isTrue);
    });

    test('reset restarts the current block and keeps earlier blocks', () {
      var state = send(initialState(), UserEventAction(Event.start));
      state = runUntil(
        state,
        (s) => s.stepIndex == 3 && s.phase == Phase.working,
      );
      final workBefore = state.totalWorkSeconds;

      state = send(state, UserEventAction(Event.reset));

      expect(state.stepIndex, 3);
      expect(state.phase, Phase.idle);
      expect(state.completedSets.length, 3);
      expect(state.completedSets.every((s) => s.blockIndex == 0), isTrue);
      expect(state.totalWorkSeconds, workBefore);
    });

    test('reset mid ramp goes back to the first set of the block', () {
      var state = send(initialState(), UserEventAction(Event.start));
      state = runUntil(state, (s) => s.stepIndex == 2);

      state = send(state, UserEventAction(Event.reset));

      expect(state.stepIndex, 0);
      expect(state.phase, Phase.idle);
      expect(state.completedSets, isEmpty);
    });
  });
}

extension on CustomWorkoutState {
  int get secondsRemainingForTest => inner.secondsRemaining;
}
