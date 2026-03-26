import 'package:lifter/features/workouts2/models/base_models.dart';
import 'package:lifter/features/workouts2/models/repeater_state.dart';
import 'package:lifter/features/workouts2/rules/workout_rules.dart';
import 'package:lifter/features/workouts2/workout_action.dart';

class RepeaterRules implements WorkoutRules<RepeaterState> {
  final RepeaterState initialConfig;
  
  RepeaterRules(this.initialConfig);

  @override
  RepeaterState reduce(RepeaterState state, WorkoutAction action) {
    return switch (action) {
      TickAction() => _handleTick(state),
      WeightReceivedAction(weightKg: var w) => _handleWeight(state, w),
      UserEventAction(event: var e) => _handleUserEvent(state, e),
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
      // In a pure reducer, we calculate what phase to resume to based on reps/sets
      return state.copyWith(phase: Phase.working); // Simplified for example
    }

    // Start
    if (event == Event.start) {
       return state.copyWith(
         phase: Phase.working, 
         secondsRemaining: state.workSeconds,
         currentPhaseDuration: state.workSeconds,
       );
    }

    return state;
  }

  RepeaterState _advancePhase(RepeaterState state) {
    final isLastRep = state.currentRep >= state.reps;
    final isLastSet = state.currentSet >= state.sets;

    if (state.phase == Phase.working) {
      if (isLastRep && isLastSet) {
        return state.copyWith(phase: Phase.done);
      } else if (isLastRep) {
        return state.copyWith(
          phase: Phase.setResting,
          currentSet: state.currentSet + 1,
          currentRep: 1,
          secondsRemaining: state.setRestSeconds,
          currentPhaseDuration: state.setRestSeconds,
        );
      } else {
        return state.copyWith(
          phase: Phase.resting,
          currentRep: state.currentRep + 1,
          secondsRemaining: state.restSeconds,
          currentPhaseDuration: state.restSeconds,
        );
      }
    } 
    
    // If resting, go back to working
    return state.copyWith(
      phase: Phase.working,
      secondsRemaining: state.workSeconds,
      currentPhaseDuration: state.workSeconds,
    );
  }
}
