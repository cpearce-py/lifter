import 'dart:math' as math;

import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/user/models/user_profile.dart';
import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/custom/custom_workout_state.dart';
import 'package:lifter/features/workouts/models/custom/workout_template.dart';
import 'package:lifter/features/workouts/models/intensity.dart';
import 'package:lifter/features/workouts/models/repeater_state.dart';
import 'package:lifter/features/workouts/rules/repeater_rules.dart';
import 'package:lifter/features/workouts/rules/workout_rules.dart';

/// Shortest rest between steps. Keeps the rest phase from having a zero
/// duration, which the progress bar can't handle.
const minTransitionSeconds = 5;

/// Turns a template into the list of Repeater runs that make up the workout.
List<WorkoutStep> compileTemplate(
  WorkoutTemplate template,
  UserSettings settings,
) {
  final steps = <WorkoutStep>[];

  for (var b = 0; b < template.blocks.length; b++) {
    final block = template.blocks[b];
    final reference = resolveReferenceWeight(
      relativeTo: block.relativeTo,
      settings: settings,
      customWeight: block.customWeight,
    );
    final restBeforeBlock = b == 0 ? 0 : template.blocks[b - 1].restAfterSeconds;

    WorkoutStep buildStep({
      required int setOffset,
      required int sets,
      required int restBefore,
    }) {
      final percentage = block.percentageForSet(setOffset);
      return WorkoutStep(
        blockIndex: b,
        block: block,
        setOffset: setOffset,
        percentage: percentage,
        restBeforeSeconds: steps.isEmpty
            ? 0
            : math.max(restBefore, minTransitionSeconds),
        seed: RepeaterState(
          sets: sets,
          reps: block.reps,
          workSeconds: block.workSeconds,
          restSeconds: block.restSeconds,
          setRestSeconds: block.setRestSeconds,
          startingHand: template.startingHand,
          currentHand: template.startingHand,
          referenceWeight: reference,
          targetIntensity: percentage / 100.0,
        ),
      );
    }

    if (block.isRamped) {
      // One step per set, so each set gets its own target.
      for (var s = 0; s < block.sets; s++) {
        steps.add(buildStep(
          setOffset: s,
          sets: 1,
          restBefore: s == 0 ? restBeforeBlock : block.setRestSeconds,
        ));
      }
    } else {
      steps.add(buildStep(
        setOffset: 0,
        sets: block.sets,
        restBefore: restBeforeBlock,
      ));
    }
  }

  return steps;
}

/// Runs each step through [RepeaterRules] and moves on to the next step
/// when the current one finishes.
class CustomWorkoutRules implements WorkoutRules<CustomWorkoutState> {
  @override
  CustomWorkoutState reduce(CustomWorkoutState state, WorkoutAction action) {
    if (action case UserEventAction(event: Event.reset)) {
      return _restartBlock(state);
    }

    final step = state.currentStep;
    final inner = RepeaterRules(step.seed).reduce(state.inner, action);

    if (inner.phase != Phase.done) {
      return state.copyWith(inner: inner);
    }

    // The step is finished; bank its sets.
    final finished = state.copyWith(
      inner: inner,
      completedSets: [
        ...state.completedSets,
        ...inner.completedSets.map((s) => _tag(s, step)),
      ],
    );

    final finishedEarly =
        action is UserEventAction && action.event == Event.finish;
    if (finishedEarly || state.isLastStep) return finished;

    return _enterStep(
      finished.copyWith(
        priorWorkSeconds: state.priorWorkSeconds + inner.accumulatedWorkSeconds,
      ),
      state.stepIndex + 1,
    );
  }

  /// Starts the next step in its rest phase. [RepeaterRules] counts the rest
  /// down and moves into the first work phase on its own.
  CustomWorkoutState _enterStep(CustomWorkoutState state, int index) {
    final step = state.steps[index];
    return state.copyWith(
      stepIndex: index,
      inner: step.seed.copyWith(
        phase: Phase.setResting,
        secondsRemaining: step.restBeforeSeconds,
        currentPhaseDuration: step.restBeforeSeconds,
      ),
    );
  }

  /// Throws away the current block's sets and goes back to its first step,
  /// waiting for the user to press start again.
  CustomWorkoutState _restartBlock(CustomWorkoutState state) {
    final blockIndex = state.currentStep.blockIndex;
    final firstStep = state.steps.indexWhere((s) => s.blockIndex == blockIndex);

    return state.copyWith(
      stepIndex: firstStep,
      inner: state.steps[firstStep].seed,
      completedSets: state.completedSets
          .where((s) => s.blockIndex != blockIndex)
          .toList(),
      // Time already spent pulling still counts.
      priorWorkSeconds:
          state.priorWorkSeconds + state.inner.accumulatedWorkSeconds,
    );
  }

  SetLog _tag(SetLog set, WorkoutStep step) {
    return set.copyWith(
      isWarmup: step.isWarmup,
      blockName: step.block.name,
      blockIndex: step.blockIndex,
    );
  }
}
