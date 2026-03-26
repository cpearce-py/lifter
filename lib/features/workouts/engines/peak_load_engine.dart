
import 'package:lifter/core/providers/graph_controller_provider.dart';
import 'package:lifter/features/workouts/engines/base_workout_engine.dart';
import 'package:lifter/features/workouts/models/peak_load_state.dart';
import 'package:lifter/features/workouts/models/workout_phases.dart';

class PeakLoadEngine extends BaseWorkoutEngine<PeakLoadState> {
  PeakLoadState _initialConfig = const PeakLoadState();
  Phase _resumePhase = Phase.working;

  @override
  PeakLoadState build() {
    ref.onDispose(() {
      stopTimers();
      stopBleListening();
    });
    return const PeakLoadState();
  }

  void initialize(PeakLoadState config) {
    stopTimers();
    ref.read(graphControllerProvider).reset(resetPeak: true);
    
    // Calculate initial target (50% bodyweight)
    final initialTarget = config.bodyWeight * 0.5;
    
    _initialConfig = config.copyWith(currentTarget: initialTarget);
    state = _initialConfig;
    
    startBleListening();
  }

  void stopHand(Hand hand) {
    bool leftStopped = state.isLeftStopped || hand == Hand.left;
    bool rightStopped = state.isRightStopped || hand == Hand.right;

    state = state.copyWith(
      isLeftStopped: leftStopped,
      isRightStopped: rightStopped,
    );

    // If both hands are stopped, the workout is entirely finished.
    if (leftStopped && rightStopped) {
      send(Event.finish);
    }
  }

  void send(Event event) {
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
    if (event == Event.finish) {
      _saveCurrentRepMax(); // Make sure we save the last reading
      state = state.copyWith(phase: Phase.done);
      stopTimers();
      stopBleListening();
      return;
    }
    if (event == Event.reset) {
      stopTimers();
      ref.read(graphControllerProvider).reset(resetPeak: true);
      state = _initialConfig;
      return;
    }
    if (event == Event.start) {
      state = _transitionToWorking(state.startingHand);
      startTimers();
      return;
    }
    if (event == Event.skip) {
      _advancePhase();
      return;
    }
  }

  void _saveCurrentRepMax() {
    if (state.currentHand == Hand.left) {
      state = state.copyWith(leftMax: state.currentRepMax);
    } else {
      state = state.copyWith(rightMax: state.currentRepMax);
    }
  }

  void _advancePhase() {
    if (state.phase == Phase.working) {
      _saveCurrentRepMax();

      // Determine the next hand
      Hand nextHand = state.currentHand == Hand.left ? Hand.right : Hand.left;
      
      // If we just finished the starting hand, and the next hand isn't stopped, do it.
      if (state.currentHand == state.startingHand && 
          ((nextHand == Hand.left && !state.isLeftStopped) || 
           (nextHand == Hand.right && !state.isRightStopped))) {
        state = _transitionToWorking(nextHand);
      } else {
        // Otherwise, both hands have had a turn (or one is stopped), time to rest!
        state = state.copyWith(
          phase: Phase.resting,
          secondsRemaining: state.restSeconds,
          currentPhaseDuration: state.restSeconds,
        );
      }
      startTimers();
    } 
    else if (state.phase == Phase.resting) {
      // Increase rep count and add 10kg to target
      final nextRep = state.repCount + 1;
      final nextTarget = (state.bodyWeight * 0.5) + (nextRep * 10.0);
      
      state = state.copyWith(repCount: nextRep, currentTarget: nextTarget);

      // Figure out who goes first this round
      if (state.startingHand == Hand.left && !state.isLeftStopped) {
        state = _transitionToWorking(Hand.left);
      } else if (state.startingHand == Hand.right && !state.isRightStopped) {
        state = _transitionToWorking(Hand.right);
      } else if (!state.isLeftStopped) {
        state = _transitionToWorking(Hand.left);
      } else {
        state = _transitionToWorking(Hand.right);
      }
      startTimers();
    }
  }

  PeakLoadState _transitionToWorking(Hand hand) {
    return state.copyWith(
      phase: Phase.working,
      currentHand: hand,
      currentRepMax: 0.0, // Reset the 7-second max tracker
      secondsRemaining: 7, // Hardcoded 7 seconds per Peak Load requirement
      currentPhaseDuration: 7,
    );
  }

  // --- Base Engine Contracts ---

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
    if (state.phase != Phase.idle && state.phase != Phase.done) {
      ref.read(graphControllerProvider).addSample(reading.weightKg);
      
      // Track the max value during this specific 7-second rep
      if (state.phase == Phase.working && reading.weightKg > state.currentRepMax) {
        state = state.copyWith(currentRepMax: reading.weightKg);
      }
    }
  }
}
