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

  PeakLoadState _handleTick(PeakLoadState state) {
    if (state.secondsRemaining > 1) {
      return state.copyWith(secondsRemaining: state.secondsRemaining - 1);
    }
    return _advancePhase(state);
  }

  PeakLoadState _handleWeight(PeakLoadState state, double weight) {
    // We only care about tracking weight if they are actively pulling (Phase.working)
    if (state.phase == Phase.working) {
      final newMax = weight > state.currentRepMax ? weight : state.currentRepMax;
      final newSum = state.currentRepSum + weight;
      final newCount = state.currentRepCount + 1;

      return state.copyWith(
        currentRepMax: newMax,
        currentRepSum: newSum,
        currentRepCount: newCount,
      );
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
      // 1. Save the max and average values achieved during this 7-second window
      var nextState = _saveRepStats(state);

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

      // 4. Otherwise, both hands have gone (or the second hand is stopped).
      // Package the RepetitionLog!
      final finishedSet = SetLog(
        repetitions: [
          RepetitionLog(
            peakLoadLeft: nextState.leftMax, 
            peakLoadRight: nextState.rightMax,
            averageLoadLeft: nextState.leftAvg,
            averageLoadRight: nextState.rightAvg,
          )
        ]
      );
      
      // Time to rest!
      return nextState.copyWith(
        phase: Phase.resting,
        completedSets: [...state.completedSets, finishedSet],
        leftMax: 0.0, rightMax: 0.0,
        leftAvg: 0.0, rightAvg: 0.0, // Clear the saved averages
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
      currentRepSum: 0.0,   // Reset running sum
      currentRepCount: 0,   // Reset running count
      secondsRemaining: 7, // Hardcoded 7-second work window
      currentPhaseDuration: 7,
    );
  }

  PeakLoadState _saveRepStats(PeakLoadState state) {
    final avg = state.currentRepCount > 0 
        ? state.currentRepSum / state.currentRepCount 
        : 0.0;

    if (state.currentHand == Hand.left) {
      return state.copyWith(leftMax: state.currentRepMax, leftAvg: avg);
    } else {
      return state.copyWith(rightMax: state.currentRepMax, rightAvg: avg);
    }
  }

  PeakLoadState _finishWorkout(PeakLoadState state) {
    // Save the final reading if they clicked finish mid-pull
    final nextState = state.phase == Phase.working ? _saveRepStats(state) : state;
    
    // Package any dangling rep data into a final set
    if (nextState.leftMax > 0 || nextState.rightMax > 0) {
      final finalSet = SetLog(
        repetitions: [
          RepetitionLog(
            peakLoadLeft: nextState.leftMax, 
            peakLoadRight: nextState.rightMax,
            averageLoadLeft: nextState.leftAvg,
            averageLoadRight: nextState.rightAvg,
          )
        ]
      );
      return nextState.copyWith(
        phase: Phase.done,
        completedSets: [...nextState.completedSets, finalSet],
        leftMax: 0.0, rightMax: 0.0,
        leftAvg: 0.0, rightAvg: 0.0,
      );
    }
    
    return nextState.copyWith(phase: Phase.done);
  }
}
