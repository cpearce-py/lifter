

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/graph_controller_provider.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/workouts/engines/base_engine.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/repeater_state.dart';
import 'package:lifter/features/workouts/rules/repeater_rules.dart';

final repeaterConfigProvider = Provider<RepeaterState>((ref) {
  throw UnimplementedError('repeaterConfigProvider must be overridden in a ProviderScope');
});

class RepeaterEngine extends BaseEngine<RepeaterState> {
  final DateTime _startTime = DateTime.now();

  // Implement the abstract method so the base class knows how to read the phase
  @override
  Phase extractPhase(RepeaterState state) => state.phase;

  @override
  RepeaterState build() {
    final config = ref.watch(repeaterConfigProvider);

    final baseTarget = config.referenceWeight * config.targetIntensity;
    final graphController = ref.read(graphControllerProvider);

    if (config.targetIntensity >= 1.0) {
      graphController.setTargets(min: baseTarget * 0.95, max: baseTarget); 
    } else {
      final minZone = baseTarget * 0.9;
      final maxZone = baseTarget * 1.1;
      graphController.setTargets(min: minZone, max: maxZone);
    }
    
    rules = RepeaterRules(config);
    currentPhase = config.phase;

    ref.onDispose(() {
      stopTimer();
      stopBle();
    });

    ref.read(graphControllerProvider).reset(resetPeak: true);
    startBle();

    return config;
  }

  @override
  WorkoutLog buildSummary(RepeaterState state) {
    final totalTime = DateTime.now().difference(_startTime).inSeconds;

    return WorkoutLog(
      workoutTypeId: 1, 
      dateDone: DateTime.now(), 
      duration: totalTime, 
      workingTime: state.accumulatedWorkSeconds, 
      sets: state.completedSets
    );
  }
}

final repeaterEngineProvider = NotifierProvider.autoDispose<RepeaterEngine, RepeaterState>(
  RepeaterEngine.new,
  dependencies: [repeaterConfigProvider],
);
