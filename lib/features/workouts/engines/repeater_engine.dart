

import 'package:lifter/core/providers/graph_controller_provider.dart';
import 'package:lifter/features/bluetooth/ble_service.dart';
import 'package:lifter/features/workouts/engines/base_workout_engine.dart';
import 'package:lifter/features/workouts/models/repeater_state.dart';
import 'package:lifter/features/workouts/models/workout_phases.dart';

class RepeaterEngine extends BaseWorkoutEngine<RepeaterState> {
  RepeaterState _initialConfig = const RepeaterState();
  Phase _resumePhase = Phase.working;

  static const _transitions = {
    (Phase.idle,       Event.start):  Phase.working,
    (Phase.paused,     Event.resume): Phase.working,
    (Phase.resting,    Event.skip):   Phase.working,
    (Phase.setResting, Event.skip):   Phase.working,
    (Phase.working,    Event.pause):  Phase.paused,
    (Phase.working,    Event.cancel): Phase.cancelled,
    (Phase.working,    Event.finish): Phase.done,
    (Phase.working,    Event.reset):  Phase.idle,
    (Phase.paused,     Event.cancel): Phase.cancelled,
    (Phase.paused,     Event.reset):  Phase.idle,
    (Phase.paused,     Event.finish): Phase.done,
  };

  @override
  RepeaterState build() {
    // Clean up streams/timers if the user leaves the page
    ref.onDispose(() {
      stopTimers();
      stopBleListening();
    });
    return const RepeaterState();
  }

  void initialize(RepeaterState config) {
    stopTimers();
    ref.read(graphControllerProvider).reset(resetPeak: true);
    
    _initialConfig = config;
    state = config;
    
    startBleListening();
  }

  void send(Event event) {
    final nextPhase = _transitions[(state.phase, event)];
    if (nextPhase == null || nextPhase == state.phase) return;

    if (event == Event.skip) {
      _advancePhase();
      return;
    }

    if (event == Event.pause) {
      _resumePhase = state.phase;
      state = state.copyWith(phase: Phase.paused);
      stopTimers();
      return;
    }

    if (event == Event.resume) {
      state = state.copyWith(phase: _resumePhase);
      startTimers();
      return;
    }

    if (event == Event.reset) {
      stopTimers();
      ref.read(graphControllerProvider).reset(resetPeak: true);
      state = _initialConfig;
      return;
    }

    state = _transitionTo(nextPhase);

    if (nextPhase == Phase.done || nextPhase == Phase.cancelled) {
      stopBleListening();
      stopTimers();
    } else if (nextPhase == Phase.working || nextPhase == Phase.resting || nextPhase == Phase.setResting) {
      startTimers();
    }
  }

  void _advancePhase() {
    final isLastRep = state.currentRep >= state.reps;
    final isLastSet = state.currentSet >= state.sets;

    if (state.phase == Phase.working) {
      if (isLastRep && isLastSet) {
        send(Event.finish);
      } else if (isLastRep) {
        state = _transitionTo(Phase.setResting).copyWith(
          currentSet: state.currentSet + 1,
          currentRep: 1,
        );
        startTimers();
      } else {
        state = _transitionTo(Phase.resting).copyWith(
          currentRep: state.currentRep + 1,
        );
        startTimers();
      }
    } else if (state.phase == Phase.resting || state.phase == Phase.setResting) {
      state = _transitionTo(Phase.working);
      startTimers();
    }
  }

  RepeaterState _transitionTo(Phase phase) {
    final duration = _secondsForPhase(phase);
    return state.copyWith(
      phase: phase,
      secondsRemaining: duration,
      currentPhaseDuration: duration,
    );
  }

  int _secondsForPhase(Phase phase) => switch (phase) {
    Phase.working    => state.workSeconds,
    Phase.resting    => state.restSeconds,
    Phase.setResting => state.setRestSeconds,
    _                => 0,
  };

  // --- Implement the Base Engine Contracts ---

  @override
  void onTimerTick() {
    if (state.secondsRemaining > 1) {
      state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
    } else {
      _advancePhase();
    }
  }

  @override
  void onWeightReceived(WeightReading reading) {
    if (state.phase != Phase.idle &&
        state.phase != Phase.done &&
        state.phase != Phase.cancelled) {
      ref.read(graphControllerProvider).addSample(reading.weightKg);
    }
  }
}
