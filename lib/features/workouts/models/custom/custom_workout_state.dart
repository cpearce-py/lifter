import 'package:flutter/material.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/custom/workout_template.dart';
import 'package:lifter/features/workouts/models/repeater_state.dart';

/// A single run of the Repeater state machine. A flat block compiles to one
/// step; a ramped block compiles to one step per set so each set can have
/// its own intensity.
@immutable
class WorkoutStep {
  final int blockIndex;
  final WorkoutBlock block;

  /// How many of the block's sets come before this step, so the UI can show
  /// "Set 2 of 3" across a ramped block.
  final int setOffset;

  /// The intensity percentage this step targets.
  final int percentage;

  /// Rest before this step starts. Zero for the very first step.
  final int restBeforeSeconds;

  /// The idle Repeater state this step starts from.
  final RepeaterState seed;

  const WorkoutStep({
    required this.blockIndex,
    required this.block,
    required this.setOffset,
    required this.percentage,
    required this.restBeforeSeconds,
    required this.seed,
  });

  bool get isWarmup => block.kind == BlockKind.warmup;
  bool get isFirstOfBlock => setOffset == 0;
  double get targetWeight => seed.referenceWeight * seed.targetIntensity;
}

@immutable
class CustomWorkoutState {
  final int? templateId;
  final String templateName;
  final List<WorkoutStep> steps;
  final int stepIndex;

  /// The Repeater state for the step that is currently running.
  final RepeaterState inner;

  /// Sets from finished steps, tagged with their block.
  final List<SetLog> completedSets;

  /// Work seconds from finished steps. The current step's are in [inner].
  final int priorWorkSeconds;

  const CustomWorkoutState({
    this.templateId,
    required this.templateName,
    required this.steps,
    this.stepIndex = 0,
    required this.inner,
    this.completedSets = const [],
    this.priorWorkSeconds = 0,
  });

  Phase get phase => inner.phase;
  WorkoutStep get currentStep => steps[stepIndex];
  bool get isLastStep => stepIndex >= steps.length - 1;
  int get blockCount => steps.isEmpty ? 0 : steps.last.blockIndex + 1;
  int get totalWorkSeconds => priorWorkSeconds + inner.accumulatedWorkSeconds;

  /// Set number within the current block, 1-based.
  int get blockSet => currentStep.setOffset + inner.currentSet;

  CustomWorkoutState copyWith({
    int? stepIndex,
    RepeaterState? inner,
    List<SetLog>? completedSets,
    int? priorWorkSeconds,
  }) {
    return CustomWorkoutState(
      templateId: templateId,
      templateName: templateName,
      steps: steps,
      stepIndex: stepIndex ?? this.stepIndex,
      inner: inner ?? this.inner,
      completedSets: completedSets ?? this.completedSets,
      priorWorkSeconds: priorWorkSeconds ?? this.priorWorkSeconds,
    );
  }
}
