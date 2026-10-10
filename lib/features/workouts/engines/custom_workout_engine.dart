import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/graph_controller_provider.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/ui/workout_theme_extension.dart';
import 'package:lifter/features/telemetry/graph_encoder.dart';
import 'package:lifter/features/workouts/engines/base_engine.dart';
import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/custom/custom_workout_state.dart';
import 'package:lifter/features/workouts/rules/custom_workout_rules.dart';
import 'package:lifter/features/workouts/ui/graph.dart';

final customWorkoutConfigProvider = Provider<CustomWorkoutState>((ref) {
  throw UnimplementedError('customWorkoutConfigProvider must be overridden in a ProviderScope');
});

class CustomWorkoutEngine extends BaseEngine<CustomWorkoutState> {
  final DateTime _startTime = DateTime.now();

  @override
  Phase extractPhase(CustomWorkoutState state) => state.phase;

  @override
  CustomWorkoutState build() {
    final config = ref.watch(customWorkoutConfigProvider);

    rules = CustomWorkoutRules();
    currentPhase = config.phase;

    ref.onDispose(() {
      stopTimer();
      stopBle();
    });

    ref.read(graphControllerProvider).reset(resetPeak: true);
    _syncGraphTargets(config);
    startBle();

    return config;
  }

  @override
  void dispatch(WorkoutAction action) {
    final oldStep = state.stepIndex;

    super.dispatch(action);

    // Each step can have its own target, so move the target zone with it.
    if (state.stepIndex != oldStep) {
      _syncGraphTargets(state);
    }
  }

  @override
  WorkoutLog buildSummary(
    CustomWorkoutState state,
    LiveGraphController graphController,
  ) {
    final totalTime = DateTime.now().difference(_startTime).inSeconds;

    final optimizedHistory = GraphOptimizer.compress(
      graphController.fullSessionHistory,
    );
    final Uint8List graphBlob = encode(optimizedHistory);

    return WorkoutLog(
      workoutTypeId: WorkoutId.custom,
      dateDone: DateTime.now(),
      duration: totalTime,
      workingTime: state.totalWorkSeconds,
      sets: state.completedSets,
      graphData: graphBlob,
      templateId: state.templateId,
      templateName: state.templateName,
    );
  }

  // Same target zones as the Repeater engine.
  void _syncGraphTargets(CustomWorkoutState state) {
    final step = state.currentStep;
    final baseTarget = step.targetWeight;
    final graphController = ref.read(graphControllerProvider);

    if (step.seed.targetIntensity >= 1.0) {
      graphController.setTargets(min: baseTarget * 0.95, max: baseTarget);
    } else {
      graphController.setTargets(min: baseTarget * 0.9, max: baseTarget * 1.1);
    }
  }
}

final customWorkoutEngineProvider =
    NotifierProvider.autoDispose<CustomWorkoutEngine, CustomWorkoutState>(
  CustomWorkoutEngine.new,
  dependencies: [customWorkoutConfigProvider],
);
