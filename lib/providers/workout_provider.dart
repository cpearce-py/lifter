import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/widgets/graph.dart';

// events that can be sent to state machine
enum Event { 
  start, 
  pause, 
  skip,
  cancel, 
  reset, 
  finish,
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

@immutable
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

class StateMachine extends Notifier<WorkoutState> {
  Timer? _countdownTimer;
  Timer? _sampleTimer;
  WorkoutState _initialState = const WorkoutState();

  final graphController = LiveGraphController(maxPoints: 200, yMax: 100.0);
  // TODO: should come from bluetooth
  static const _sampleHz = 20; 
  // mock data
  double _phase = 0;

  static const _transitions = {
    (Phase.idle,    Event.start):  Phase.working,
    (Phase.paused,  Event.start):  Phase.working,
    (Phase.working, Event.pause):  Phase.paused,
    (Phase.working, Event.cancel): Phase.cancelled,
    (Phase.paused,  Event.cancel): Phase.cancelled,
    (Phase.working, Event.reset):  Phase.idle,
    (Phase.paused,  Event.reset):  Phase.idle,
    (Phase.paused,  Event.finish): Phase.done,
  };

  // Called by the UI when the user is ready to begin
  void initialize(WorkoutState ws) {
    _cancelTimers();
    graphController.reset(resetPeak: true);
    _initialState = ws;
    state = ws;
  }

  void reset() {
    _cancelTimers();
    graphController.reset(resetPeak: true);
    state = _initialState;
  }

  void send(Event event) {
    final nextPhase = _transitions[(state.phase, event)];
    if (nextPhase == null || nextPhase == state.phase) return;

    state = state.copyWith(
      phase: nextPhase,
      secondsRemaining: _secondsForPhase(nextPhase),
    );

    if (nextPhase == Phase.working || nextPhase == Phase.resting) {
      _startTimers();
    } else {
      _cancelTimers();
    }
  }

  void _advancePhase() {
    final isLastRep = state.currentRep >= state.reps;
    final isLastSet = state.currentSet >= state.sets;

    if (state.phase == Phase.working) {
      graphController.reset(resetPeak: false);
      if (isLastRep && isLastSet) {
        send(Event.finish);
      } else if (isLastRep) {
        state = state.copyWith(
          phase: Phase.setResting,
          secondsRemaining: state.setRestSeconds,
          currentSet: state.currentSet + 1,
          currentRep: 1,
        );
        _startTimers();
      } else {
        state = state.copyWith(
          phase: Phase.resting,
          secondsRemaining: state.restSeconds,
          currentRep: state.currentRep + 1,
        );
        _startTimers();
      }
    } else if (state.phase == Phase.resting || state.phase == Phase.setResting) {
      state = state.copyWith(
        phase: Phase.working,
        secondsRemaining: state.workSeconds,
      );
      _startTimers();
    }
  }

  double _readSenor() {
    _phase += 2 * pi / _sampleHz;
    final base = sin(_phase) * 30 + 50;
    final wobble = sin(_phase * 4.7) * 8;
    final noise = (Random().nextDouble() - 0.5) * 6;
    return (base + wobble + noise).clamp(0, 100);
  }

  int _secondsForPhase(Phase phase) => switch (phase) {
    Phase.working    => state.workSeconds,
    Phase.resting    => state.restSeconds,
    Phase.setResting => state.setRestSeconds,
    _                => 0,
  };

  void _cancelTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _sampleTimer?.cancel();
    _sampleTimer = null;
  }

  void _startTimers() {
    _cancelTimers();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), _onCountdownTick);
    _sampleTimer = Timer.periodic(
      Duration(milliseconds: 1000 ~/ _sampleHz),
      _onSampleTick,
    );
  }

  void _onSampleTick(Timer t) {
    if (state.phase == Phase.working) {
      graphController.addSample(_readSenor());
    }
  }

  void _onCountdownTick(Timer t) {
    if (state.secondsRemaining > 1) {
      state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);;
    } else {
      _advancePhase();
    }
  }

  @override
  WorkoutState build() {
    ref.onDispose(() {
      _cancelTimers; // clean up timer if provider is destroyed
      graphController.dispose();
    });
    return const WorkoutState();
  }
}

final workoutNotifierProvider = NotifierProvider<StateMachine, WorkoutState>(() {
  return StateMachine();
});

final graphControllerProvider = Provider<LiveGraphController>((ref) {
  return ref.watch(workoutNotifierProvider.notifier).graphController;
});

String getPrimaryLabelForState(Phase phase) => switch (phase) {
  Phase.idle => "Start",
  Phase.paused => "Resume",
  Phase.cancelled => "Cancelled", 
  Phase.working => "Pause",
  Phase.done => "Finished!",
  Phase.resting => "Skip Rest",
  Phase.setResting => "Skip Rest"
};

Event? primaryButtonEvent(Phase phase) => switch (phase) {
  Phase.idle => Event.start,
  Phase.paused => Event.start,
  Phase.working => Event.pause,
  Phase.resting => Event.skip,
  _ => null,
};