
import 'package:flutter/material.dart';
import 'package:lifter/features/history/models/log_models.dart';
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
  final double referenceWeight;
  final double targetIntensity;

  final Hand startingHand;
  final Hand currentHand;

  // history
  final double currentPullMax;
  final double savedFirstHandMax;
  final int accumulatedWorkSeconds;
  final List<RepetitionLog> currentSetReps;
  final List<SetLog> completedSets;

  final double currentPullSum;
  final int currentPullCount;
  final double savedFirstHandSum;
  final int savedFirstHandCount;

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
    this.currentPullMax = 0.0,
    this.savedFirstHandMax = 0.0,
    this.accumulatedWorkSeconds = 0,
    this.currentSetReps = const [],
    this.completedSets = const [],
    required this.referenceWeight,
    this.targetIntensity = 1,
    this.currentPullSum = 0.0,
    this.currentPullCount = 0,
    this.savedFirstHandSum = 0.0,
    this.savedFirstHandCount = 0,
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
    double? currentPullMax,
    double? savedFirstHandMax,
    int? accumulatedWorkSeconds,
    List<RepetitionLog>? currentSetReps,
    List<SetLog>? completedSets,
    double? referenceWeight,
    double? targetIntensity,

    double? currentPullSum,
    int? currentPullCount,
    double? savedFirstHandSum,
    int? savedFirstHandCount,
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
      referenceWeight: referenceWeight ?? this.referenceWeight,
      targetIntensity: targetIntensity ?? this.targetIntensity,
      startingHand: startingHand ?? this.startingHand,
      currentHand: currentHand ?? this.currentHand,
      currentPullMax: currentPullMax ?? this.currentPullMax,
      savedFirstHandMax: savedFirstHandMax ?? this.savedFirstHandMax,
      accumulatedWorkSeconds: accumulatedWorkSeconds ?? this.accumulatedWorkSeconds,
      currentSetReps: currentSetReps ?? this.currentSetReps,
      completedSets: completedSets ?? this.completedSets,
      currentPullSum: currentPullSum ?? this.currentPullSum,
      currentPullCount: currentPullCount ?? this.currentPullCount,
      savedFirstHandSum: savedFirstHandSum ?? this.savedFirstHandSum,
      savedFirstHandCount: savedFirstHandCount ?? this.savedFirstHandCount,
    );
  }
}
