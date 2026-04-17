// features/workouts/orchestrators/peak_load_orchestrator.dart
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/graph_controller_provider.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/telemetry/graph_encoder.dart';
import 'package:lifter/features/workouts/engines/base_engine.dart';
import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/models/peak_load_state.dart';
import 'package:lifter/features/workouts/models/base_models.dart'; // For Phase
import 'package:lifter/features/workouts/rules/peak_load_rules.dart';
import 'package:lifter/features/workouts/ui/graph.dart';

final peakLoadConfigProvider = Provider<PeakLoadState>((ref) {
  throw UnimplementedError('peakLoadConfigProvider must be overridden in a ProviderScope');
});

class PeakLoadEngine extends BaseEngine<PeakLoadState> {
  final DateTime _startTime = DateTime.now();
  
  @override
  Phase extractPhase(PeakLoadState state) => state.phase;

  @override
  PeakLoadState build() {
    final config = ref.watch(peakLoadConfigProvider);
    
    rules = PeakLoadRules(config);
    currentPhase = config.phase;

    ref.onDispose(() {
      stopTimer();
      stopBle();
    });

    final target = config.bodyWeight * 0.5;

    final graphController = ref.read(graphControllerProvider);
    graphController.reset(resetPeak: true);
    _syncGraphTargets(target);

    startBle();

    return config.copyWith(
      currentTarget: target,
      repCount: 1, // Start at rep 1
    );
  }

  @override
  WorkoutLog buildSummary(PeakLoadState state, LiveGraphController graphController) {
    final duration = DateTime.now().difference(_startTime).inSeconds;
    final Uint8List graphBlob = encode(graphController.fullSessionHistory);

    int actualWorkingTime = 0;
    for (final setLog in state.completedSets) {
      for (final rep in setLog.repetitions) {
        if (rep.peakLoadLeft > 0) actualWorkingTime += 7;
        if (rep.peakLoadRight > 0) actualWorkingTime += 7;
      }
    }

    return WorkoutLog(
      workoutTypeId: 2, 
      dateDone: DateTime.now(), 
      duration: duration, 
      workingTime: actualWorkingTime,
      sets: state.completedSets,
      graphData: graphBlob,
    );
  }

  @override
  void dispatch(WorkoutAction action) {
    final oldTarget = state.currentTarget;

    // Let the BaseEngine and Rules do their normal thing
    super.dispatch(action); 
    
    // Check if the rules decided to change the target during that tick/event
    if (state.currentTarget != oldTarget) {
      _syncGraphTargets(state.currentTarget);
    }
  }

  void _syncGraphTargets(double baseTarget) {
    final minZone = baseTarget * 0.90;
    final maxZone = baseTarget * 1.10;
    
    ref.read(graphControllerProvider).setTargets(min: minZone, max: maxZone);
  }
}

final peakLoadEngineProvider = NotifierProvider.autoDispose<PeakLoadEngine, PeakLoadState>(
  PeakLoadEngine.new,
  dependencies: [peakLoadConfigProvider], 
);

