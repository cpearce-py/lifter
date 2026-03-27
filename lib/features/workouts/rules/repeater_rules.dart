import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/repeater_state.dart';
import 'package:lifter/features/workouts/rules/workout_rules.dart';

class RepeaterRules implements WorkoutRules<RepeaterState> {
  final RepeaterState initialConfig;
  
  RepeaterRules(this.initialConfig);

  @override
  RepeaterState reduce(RepeaterState state, WorkoutAction action) {
    return switch (action) {
      TickAction() => _handleTick(state),
      WeightReceivedAction(weightKg: var w) => _handleWeight(state, w),
      UserEventAction(event: var e) => _handleUserEvent(state, e),
      StopHandAction() => state,
    };
  }

  RepeaterState _handleWeight(RepeaterState state, double weight) {
    // The state machine doesn't care about the graph! 
    // It just ignores weight unless we need it for logic (like Peak Load would).
    return state; 
  }

  RepeaterState _handleTick(RepeaterState state) {
    if (state.secondsRemaining > 1) {
      return state.copyWith(secondsRemaining: state.secondsRemaining - 1);
    }
    return _advancePhase(state);
  }

  RepeaterState _handleUserEvent(RepeaterState state, Event event) {
    if (event == Event.reset) return initialConfig;
    if (event == Event.pause) return state.copyWith(phase: Phase.paused);
    if (event == Event.skip) return _advancePhase(state);
  
    // Resume
    if (event == Event.resume) {
      return state.copyWith(phase: Phase.working); // Simplified for example
    }

    // Start
    if (event == Event.start) {
       return state.copyWith(
         phase: Phase.working, 
         currentHand: state.startingHand, // Should be setup in UI but not sure
         secondsRemaining: state.workSeconds,
         currentPhaseDuration: state.workSeconds,
       );
    }

    return state;
  }

  RepeaterState _advancePhase(RepeaterState state) {
    if (state.phase == Phase.working) {
      if (state.currentHand == state.startingHand) {
        final nextHand = state.currentHand == Hand.left ? Hand.right : Hand.left;
        return state.copyWith(
          phase: Phase.switching,
          currentHand: nextHand,
          secondsRemaining: state.switchSeconds,
          currentPhaseDuration: state.switchSeconds,
        );
      }
    }
    final isLastRep = state.currentRep >= state.reps;
    final isLastSet = state.currentSet >= state.sets;

    final resetHand = state.startingHand;

    if (state.phase == Phase.working) {
      if (isLastRep && isLastSet) {
        return state.copyWith(phase: Phase.done);
      } else if (isLastRep) {
        return state.copyWith(
          phase: Phase.setResting,
          currentSet: state.currentSet + 1,
          currentRep: 1,
          currentHand: resetHand,
          secondsRemaining: state.setRestSeconds,
          currentPhaseDuration: state.setRestSeconds,
        );
      } else {
        return state.copyWith(
          phase: Phase.resting,
          currentRep: state.currentRep + 1,
          currentHand: resetHand,
          secondsRemaining: state.restSeconds,
          currentPhaseDuration: state.restSeconds,
        );
      }
    } 

    // Coming out of the switching phase -> Back to work! 
    if (state.phase == Phase.switching) {
      return state.copyWith(
        phase: Phase.working,
        secondsRemaining: state.workSeconds,
        currentPhaseDuration: state.workSeconds,
      );
    }
    
    // If resting, go back to working
    return state.copyWith(
      phase: Phase.working,
      secondsRemaining: state.workSeconds,
      currentPhaseDuration: state.workSeconds,
    );
  }
}
