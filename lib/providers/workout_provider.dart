import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// events that can be sent to state machine
enum Event { 
  start, 
  pause, 
  cancel, 
  reset, 
  finish 
}

// Phase's of the state machine
enum Phase {
  idle,       // not yet started
  working,    // actively hanging — graph recording
  resting,    // rest between reps
  setResting, // longer rest between sets
  paused,     // frozen mid-phase; resumes to _resumePhase
  done,       // all sets and reps complete
  cancelled,
}

class WorkoutState {
  final int sets;
  final int reps;
  final int workSeconds;
  final int restSeconds;
  final int setRestSeconds;
  final Phase phase;
  final int currentSet;
  final int currentRep;
  final int secondsRemaining;

  const WorkoutState({
    this.sets = 1,
    this.reps = 1,
    this.workSeconds = 30,
    this.restSeconds = 10,
    this.setRestSeconds = 60,
    this.phase = Phase.idle,
    this.currentSet = 1,
    this.currentRep = 1,
    this.secondsRemaining = 0,
  });

  WorkoutState copyWith({
    int? sets,
    int? reps,
    int? workSeconds,
    int? restSeconds,
    int? setRestSeconds,
    Phase? phase,
    int? currentSet,
    int? currentRep,
    int? secondsRemaining,
  }) {
    return WorkoutState(
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      workSeconds: workSeconds ?? this.workSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      setRestSeconds: setRestSeconds ?? this.setRestSeconds,
      phase: phase ?? this.phase,
      currentSet: currentSet ?? this.currentSet,
      currentRep: currentRep ?? this.currentRep,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    );
  }
}

class StateMachine extends Notifier<Phase> {
  Timer? _ticker;

  // Map<current phase + event type): resulting phase>
  static const _transitions = {
    (Phase.idle, Event.start): Phase.working,
    (Phase.working,    Event.pause):  Phase.paused,
    (Phase.working,    Event.cancel): Phase.cancelled,
    (Phase.paused,     Event.start):  Phase.working,
    (Phase.paused,     Event.cancel): Phase.cancelled,
    (Phase.paused,     Event.reset):  Phase.idle,
    (Phase.paused,     Event.finish): Phase.done,
  };

  void send(Event event) {
    final next = _transitions[(state, event)];
    if (next != null && next != state) state = next;
  }

  // initial state
  @override
  Phase build() => Phase.idle;
}

final workoutNotifierProvider = NotifierProvider<StateMachine, Phase>(() {
  return StateMachine();
});
