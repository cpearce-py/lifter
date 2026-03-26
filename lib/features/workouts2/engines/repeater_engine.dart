

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/graph_controller_provider.dart';
import 'package:lifter/features/workouts2/engine.dart';
import 'package:lifter/features/workouts2/models/base_models.dart';
import 'package:lifter/features/workouts2/models/repeater_state.dart';
import 'package:lifter/features/workouts2/rules/repeater_rules.dart';

final repeaterConfigProvider = Provider<RepeaterState>((ref) {
  throw UnimplementedError('repeaterConfigProvider must be overridden in a ProviderScope');
});

// 2. The Specific Orchestrator
class RepeaterOrchestrator extends BaseWorkoutOrchestrator<RepeaterState> {
  
  // Implement the abstract method so the base class knows how to read the phase
  @override
  Phase extractPhase(RepeaterState state) => state.phase;

  @override
  RepeaterState build() {
    // A. Read the injected config
    final config = ref.watch(repeaterConfigProvider);
    
    // B. Set up the specific rules and initial phase tracker
    rules = RepeaterRules(config);
    currentPhase = config.phase;

    // C. Register cleanup
    ref.onDispose(() {
      stopTimer();
      stopBle();
    });

    // D. Safely start hardware
    Future.microtask(() {
      ref.read(graphControllerProvider).reset(resetPeak: true);
      startBle();
    });

    // E. Return the initial state
    return config;
  }
}

// 3. The Orchestrator Provider
final repeaterOrchestratorProvider = NotifierProvider.autoDispose<RepeaterOrchestrator, RepeaterState>(
  RepeaterOrchestrator.new,
  dependencies: [repeaterConfigProvider],
);
