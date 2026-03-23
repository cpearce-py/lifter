import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/scale_provider.dart';
import 'package:lifter/features/bluetooth/ble_service.dart';
import 'package:lifter/features/workouts/graph.dart';

// events that can be sent to state machine
enum Event { 
  start, 
  pause, 
  resume,
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
  final int currentPhaseDuration;

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
    this.currentPhaseDuration = 0,
  });

  int get elapsedSeconds => currentPhaseDuration - secondsRemaining;

  double get phaseProgress {
    if (currentPhaseDuration == 0) return 0;
    return elapsedSeconds / currentPhaseDuration;
  }

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
    int? currentPhaseDuration,
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
      currentPhaseDuration: currentPhaseDuration ?? this.currentPhaseDuration,
    );
  }
}


class StateMachine extends Notifier<WorkoutState> {
  Timer? _countdownTimer;
  StreamSubscription<WeightReading>? _scaleSub;
  WorkoutState _initialState = const WorkoutState();
  Phase _resumePhase = Phase.working;

  final graphController = LiveGraphController(yMax: 150.0);

  static const _transitions = {
    (Phase.idle,    Event.start):  Phase.working,
    (Phase.paused,  Event.resume):  Phase.working,
    (Phase.resting, Event.skip): Phase.working,
    (Phase.working, Event.pause):  Phase.paused,
    (Phase.working, Event.cancel): Phase.cancelled,
    (Phase.working, Event.finish): Phase.done,
    (Phase.working, Event.reset):  Phase.idle,
    (Phase.paused,  Event.cancel): Phase.cancelled,
    (Phase.paused,  Event.reset):  Phase.idle,
    (Phase.paused,  Event.finish): Phase.done,
    (Phase.setResting, Event.skip): Phase.working,
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

    if (event == Event.skip) {
      _advancePhase();
      return;
    }

    if (event == Event.pause) {
      _resumePhase = state.phase;
      state = state.copyWith(phase: Phase.paused);
      _cancelTimers();
      return;
    }

    if (event == Event.resume) {
      state = state.copyWith(phase: _resumePhase);
      _startTimers();
      return;
    }

    state = _transitionTo(nextPhase);

    if (nextPhase == Phase.working || nextPhase == Phase.resting || nextPhase == Phase.setResting) {
      _startTimers();
    } else {
      _cancelTimers();
    }
  }

  void _advancePhase() {
    final isLastRep = state.currentRep >= state.reps;
    final isLastSet = state.currentSet >= state.sets;

    if (state.phase == Phase.working) {
      // graphController.reset(resetPeak: false);
      if (isLastRep && isLastSet) {
        send(Event.finish);
      } else if (isLastRep) {
        state = _transitionTo(Phase.setResting).copyWith(
          currentSet: state.currentSet + 1,
          currentRep: 1,
        );
        _startTimers();
      } else {
        state = _transitionTo(Phase.resting).copyWith(
          currentRep: state.currentRep + 1,
        );
        _startTimers();
      }
    } else if (state.phase == Phase.resting || state.phase == Phase.setResting) {
      state = _transitionTo(Phase.working);
      _startTimers();
    }
  }

  WorkoutState _transitionTo(Phase phase) {
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

  void _cancelTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _startTimers() {
    _cancelTimers();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), _onCountdownTick);
  }

  void _onCountdownTick(Timer t) {
    if (state.secondsRemaining > 1) {
      state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
    } else {
      _advancePhase();
    }
  }

  @override
  WorkoutState build() {
    _scaleSub = ref
      .read(weiHengServiceProvider)
      .weightStream
      .listen((reading) {
        if (state.phase == Phase.working) {
          graphController.addSample(reading.weightKg);
          }
        });

    ref.onDispose(() {
      _cancelTimers(); // clean up timer if provider is destroyed
      _scaleSub?.cancel();
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

String getPrimaryLabelForPhase(Phase phase) => switch (phase) {
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
  Phase.paused => Event.resume,
  Phase.working => Event.pause,
  Phase.resting => Event.skip,
  Phase.setResting => Event.skip,
  _ => null,
};

String secondaryLabelForPhase(Phase phase) => switch (phase) {
  Phase.working    => 'HANG',
  Phase.resting    => 'REST',
  Phase.setResting => 'SET REST',
  Phase.paused     => 'PAUSED',
  Phase.idle       => 'READY',
  Phase.done       => 'DONE ✓',
  _ => "",
};

Color accentColorForPhase(Phase phase) => switch (phase) {
  Phase.working    => const Color(0xFFE8FF47),
  Phase.resting    => const Color(0xFF47C8FF),
  Phase.setResting => const Color(0xFFB47FFF),
  Phase.paused     => const Color(0xFFFF7F7F),
  Phase.done       => const Color(0xFF81FF7F),
  _                => const Color(0xFFE8FF47),
};
