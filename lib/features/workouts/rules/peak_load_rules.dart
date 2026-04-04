import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/peak_load_state.dart';
import 'package:lifter/features/workouts/rules/workout_rules.dart';

class PeakLoadRules implements WorkoutRules<PeakLoadState> {
  final PeakLoadState initialConfig;
  
  PeakLoadRules(this.initialConfig);

  @override
  PeakLoadState reduce(PeakLoadState state, WorkoutAction action) {
    return switch (action) {
      TickAction() => _handleTick(state),
      WeightReceivedAction(weightKg: var w) => _handleWeight(state, w),
      StopHandAction(hand: var h) => _handleStopHand(state, h),
      UserEventAction(event: var e) => _handleUserEvent(state, e),
    };
  }

  // --- Input Handlers ---

  PeakLoadState _handleTick(PeakLoadState state) {
    if (state.secondsRemaining > 1) {
      return state.copyWith(secondsRemaining: state.secondsRemaining - 1);
    }
    return _advancePhase(state);
  }

  PeakLoadState _handleWeight(PeakLoadState state, double weight) {
    // We only care about tracking weight if they are actively pulling (Phase.working)
    if (state.phase == Phase.working && weight > state.currentRepMax) {
      return state.copyWith(currentRepMax: weight);
    }
    return state;
  }

  PeakLoadState _handleStopHand(PeakLoadState state, Hand hand) {
    final isLeftStopped = state.isLeftStopped || hand == Hand.left;
    final isRightStopped = state.isRightStopped || hand == Hand.right;

    // If both hands are now stopped, the workout is entirely finished!
    if (isLeftStopped && isRightStopped) {
      return _finishWorkout(state.copyWith(
        isLeftStopped: isLeftStopped,
        isRightStopped: isRightStopped,
      ));
    }

    return state.copyWith(
      isLeftStopped: isLeftStopped,
      isRightStopped: isRightStopped,
    );
  }

  PeakLoadState _handleUserEvent(PeakLoadState state, Event event) {
    if (event == Event.reset) return initialConfig.copyWith(currentTarget: initialConfig.bodyWeight * 0.5);
    if (event == Event.pause) return state.copyWith(phase: Phase.paused);
    if (event == Event.skip) return _advancePhase(state);
    if (event == Event.finish) return _finishWorkout(state);
    
    if (event == Event.resume) {
      return state.copyWith(phase: Phase.working);
    }

    if (event == Event.start) {
      // First rep calculation: 50% of body weight
      const prepTime = 5;
      return state.copyWith(
        phase: Phase.starting,
        currentTarget: state.bodyWeight * 0.5,
        repCount: 1,
        currentHand: state.startingHand, 
        secondsRemaining: prepTime,
        currentPhaseDuration: prepTime,
      );
    }

    return state;
  }

  // --- Phase Advancement Logic ---

  PeakLoadState _advancePhase(PeakLoadState state) {
    if (state.phase == Phase.starting) {
      return _startWorkingPhase(state, state.currentHand);
    }
    if (state.phase == Phase.working) {
      // 1. Save the max value achieved during this 7-second window
      var nextState = _saveRepMax(state);

      // 2. Figure out what hand goes next
      final nextHand = state.currentHand == Hand.left ? Hand.right : Hand.left;
      
      // 3. Did we just finish the first hand, and the second hand is still active?
      if (state.currentHand == state.startingHand) {
        if (nextHand == Hand.left && !nextState.isLeftStopped) {
          return _startSwitchingPhase(nextState, Hand.left);
        }
        if (nextHand == Hand.right && !nextState.isRightStopped) {
          return _startSwitchingPhase(nextState, Hand.right);
        }
      }

      final finishedSet = SetLog(
        repetitions: [
          RepetitionLog(
            peakLoadLeft: nextState.leftMax, 
            peakLoadRight: nextState.rightMax
          )
        ]
      );
      
      // 4. Otherwise, both hands have gone (or the second hand is stopped). Time to rest!
      return nextState.copyWith(
        phase: Phase.resting,
        completedSets: [...state.completedSets, finishedSet],
        leftMax: 0,
        rightMax: 0,
        secondsRemaining: state.restSeconds,
        currentPhaseDuration: state.restSeconds,
      );
    } 

    if (state.phase == Phase.switching) {
      return _startWorkingPhase(state, state.currentHand);
    }
    
    if (state.phase == Phase.resting) {
      // 1. Increase the loop parameters for the next round
      final nextRep = state.repCount + 1;
      final nextTarget = (state.bodyWeight * 0.5) + (state.repCount * 10.0);
      
      var nextState = state.copyWith(
        repCount: nextRep,
        currentTarget: nextTarget,
      );

      // 2. Figure out who goes first this round
      if (state.startingHand == Hand.left && !state.isLeftStopped) {
        return _startWorkingPhase(nextState, Hand.left);
      } else if (state.startingHand == Hand.right && !state.isRightStopped) {
        return _startWorkingPhase(nextState, Hand.right);
      } else if (!state.isLeftStopped) {
        return _startWorkingPhase(nextState, Hand.left);
      } else {
        return _startWorkingPhase(nextState, Hand.right); // Fallback
      }
    }

    return state;
  }

  PeakLoadState _startSwitchingPhase(PeakLoadState state, Hand nextHand) {
    return state.copyWith(
      phase: Phase.switching,
      currentHand: nextHand, // Update hand so the UI knows who to prompt
      secondsRemaining: 5,   // 5 seconds to swap hands
      currentPhaseDuration: 5,
    );
  }

  // --- Helpers ---

  PeakLoadState _startWorkingPhase(PeakLoadState state, Hand hand) {
    return state.copyWith(
      phase: Phase.working,
      currentHand: hand,
      currentRepMax: 0.0,  // Reset the max tracker for this new 7s window
      secondsRemaining: 7, // Hardcoded 7-second work window
      currentPhaseDuration: 7,
    );
  }

  PeakLoadState _saveRepMax(PeakLoadState state) {
    if (state.currentHand == Hand.left) {
      return state.copyWith(leftMax: state.currentRepMax);
    } else {
      return state.copyWith(rightMax: state.currentRepMax);
    }
  }

  PeakLoadState _finishWorkout(PeakLoadState state) {
    // If they click finish mid-rep, make sure we save that final reading
    final finalState = state.phase == Phase.working ? _saveRepMax(state) : state;
    return finalState.copyWith(phase: Phase.done);
  }
}
