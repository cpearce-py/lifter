// features/workouts/orchestrators/peak_load_orchestrator.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/graph_controller_provider.dart';
import 'package:lifter/features/workouts/engines/base_engine.dart';
import 'package:lifter/features/workouts/models/peak_load_state.dart';
import 'package:lifter/features/workouts/models/base_models.dart'; // For Phase
import 'package:lifter/features/workouts/rules/peak_load_rules.dart';

final peakLoadConfigProvider = Provider<PeakLoadState>((ref) {
  throw UnimplementedError('peakLoadConfigProvider must be overridden in a ProviderScope');
});

class PeakLoadEngine extends BaseEngine<PeakLoadState> {
  
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

    ref.read(graphControllerProvider).reset(resetPeak: true);
    startBle();

    return config.copyWith(
      currentTarget: config.bodyWeight * 0.5,
      repCount: 1, // Start at rep 1
    );
  }
}

final peakLoadEngineProvider = NotifierProvider.autoDispose<PeakLoadEngine, PeakLoadState>(
  PeakLoadEngine.new,
  dependencies: [peakLoadConfigProvider], 
);

