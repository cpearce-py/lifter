
import 'package:flutter/material.dart';
import 'package:lifter/features/workouts/models/base_models.dart';


@immutable
class RepeaterState {
  final int sets;
  final int reps;
  final int workSeconds;
  final int restSeconds;
  final int setRestSeconds;
  final int switchSeconds;
  final Phase phase;
  final int currentSet;
  final int currentRep;
  final int secondsRemaining;
  final int currentPhaseDuration;

  final Hand startingHand;
  final Hand currentHand;

  const RepeaterState({
    this.sets = 1,
    this.reps = 1,
    this.workSeconds = 30,
    this.restSeconds = 10,
    this.setRestSeconds = 60,
    this.switchSeconds = 5,
    this.phase = Phase.idle,
    this.currentSet = 1,
    this.currentRep = 1,
    this.secondsRemaining = 0,
    this.currentPhaseDuration = 0,
    this.startingHand = Hand.left,
    this.currentHand = Hand.left,
  });

  int get elapsedSeconds => currentPhaseDuration - secondsRemaining;

  double get phaseProgress {
    if (currentPhaseDuration == 0) return 0;
    return elapsedSeconds / currentPhaseDuration;
  }

  RepeaterState copyWith({
    int? sets,
    int? reps,
    int? workSeconds,
    int? restSeconds,
    int? setRestSeconds,
    int? switchSeconds,
    Phase? phase,
    int? currentSet,
    int? currentRep,
    int? secondsRemaining,
    int? currentPhaseDuration,
    Hand? startingHand,
    Hand? currentHand,
  }) {
    return RepeaterState(
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      workSeconds: workSeconds ?? this.workSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      setRestSeconds: setRestSeconds ?? this.setRestSeconds,
      switchSeconds: switchSeconds ?? this.switchSeconds,
      phase: phase ?? this.phase,
      currentSet: currentSet ?? this.currentSet,
      currentRep: currentRep ?? this.currentRep,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      currentPhaseDuration: currentPhaseDuration ?? this.currentPhaseDuration,
      startingHand: startingHand ?? this.startingHand,
      currentHand: currentHand ?? this.currentHand,
    );
  }
}
