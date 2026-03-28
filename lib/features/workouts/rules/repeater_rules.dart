import 'package:lifter/features/history/models/log_models.dart';
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
    if (state.phase == Phase.working && weight > state.currentPullMax) {
      return state.copyWith(currentPullMax: weight);
    }
    return state; 
  }

  RepeaterState _handleTick(RepeaterState state) {
    final newAccumulatedTime = state.phase == Phase.working
          ? state.accumulatedWorkSeconds + 1
          : state.accumulatedWorkSeconds;
    if (state.secondsRemaining > 1) {
      return state.copyWith(
        secondsRemaining: state.secondsRemaining - 1,
        accumulatedWorkSeconds: newAccumulatedTime);
    }
    return _advancePhase(state.copyWith(accumulatedWorkSeconds: newAccumulatedTime));
  }

  RepeaterState _handleUserEvent(RepeaterState state, Event event) {
    if (event == Event.reset) return initialConfig;
    if (event == Event.pause) return state.copyWith(phase: Phase.paused);
    if (event == Event.skip) return _advancePhase(state);
    if (event == Event.finish) return _finishWorkoutEarly(state);
  
    // Resume
    if (event == Event.resume) {
      return state.copyWith(phase: Phase.working);
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
      
      // A. Did we only finish the FIRST hand for this rep?
      if (state.currentHand == state.startingHand) {
        final nextHand = state.currentHand == Hand.left ? Hand.right : Hand.left;
        return state.copyWith(
          phase: Phase.switching,
          currentHand: nextHand,
          savedFirstHandMax: state.currentPullMax, // Save hand 1's max!
          currentPullMax: 0.0,                     // Reset the scale for hand 2
          secondsRemaining: state.switchSeconds,
          currentPhaseDuration: state.switchSeconds,
        );
      }

      // B. If we are here, BOTH hands have finished. Package the RepetitionLog!
      final leftMax = state.startingHand == Hand.left ? state.savedFirstHandMax : state.currentPullMax;
      final rightMax = state.startingHand == Hand.right ? state.savedFirstHandMax : state.currentPullMax;
      
      final newRep = RepetitionLog(peakLoadLeft: leftMax, peakLoadRight: rightMax);
      final updatedRepsList = [...state.currentSetReps, newRep];

      final isLastRep = state.currentRep >= state.reps;
      final isLastSet = state.currentSet >= state.sets;
      final resetHand = state.startingHand; 

      // C. Are we completely done with the Workout?
      if (isLastRep && isLastSet) {
        // Package the final set
        final finalSet = SetLog(repetitions: updatedRepsList);
        return state.copyWith(
          phase: Phase.done,
          completedSets: [...state.completedSets, finalSet],
          currentSetReps: [], // Clear it out
          currentPullMax: 0.0,
          savedFirstHandMax: 0.0,
        );
      } 
      
      // D. Are we done with the Set?
      if (isLastRep) {
        // Package the completed set
        final completedSet = SetLog(repetitions: updatedRepsList);
        return state.copyWith(
          phase: Phase.setResting,
          completedSets: [...state.completedSets, completedSet],
          currentSetReps: [], // Clear it out for the next set
          currentSet: state.currentSet + 1,
          currentRep: 1,
          currentHand: resetHand,
          currentPullMax: 0.0,
          savedFirstHandMax: 0.0,
          secondsRemaining: state.setRestSeconds,
          currentPhaseDuration: state.setRestSeconds,
        );
      } 
      
      // E. Otherwise, just a normal Rep Rest
      return state.copyWith(
        phase: Phase.resting,
        currentSetReps: updatedRepsList, // Keep the running list of reps
        currentRep: state.currentRep + 1,
        currentHand: resetHand,
        currentPullMax: 0.0,
        savedFirstHandMax: 0.0,
        secondsRemaining: state.restSeconds,
        currentPhaseDuration: state.restSeconds,
      );
    } 
    
    // Returning to Phase.working
    if (state.phase == Phase.switching) {
      return state.copyWith(
        phase: Phase.working,
        secondsRemaining: state.workSeconds,
        currentPhaseDuration: state.workSeconds,
      );
    }
    
    return state.copyWith(
      phase: Phase.working,
      secondsRemaining: state.workSeconds,
      currentPhaseDuration: state.workSeconds,
    );
  }

  RepeaterState _finishWorkoutEarly(RepeaterState state) {
    List<SetLog> finalSets = List.from(state.completedSets);
    List<RepetitionLog> finalReps = List.from(state.currentSetReps);
    if (state.currentPullMax > 0 || state.savedFirstHandMax > 0) {
      final leftMax = state.startingHand == Hand.left ? state.savedFirstHandMax : state.currentPullMax;
      final rightMax = state.startingHand == Hand.right ? state.savedFirstHandMax : state.currentPullMax;
      
      finalReps.add(RepetitionLog(peakLoadLeft: leftMax, peakLoadRight: rightMax));
    }

    // Are there any reps floating around that haven't been packaged into a set yet?
    if (finalReps.isNotEmpty) {
      finalSets.add(SetLog(repetitions: finalReps));
    }

    // Return the fully finalized state
    return state.copyWith(
      phase: Phase.done,
      completedSets: finalSets,
      currentSetReps: [], // Clear out the temp list
      currentPullMax: 0.0,
      savedFirstHandMax: 0.0,
    );
  }
}
