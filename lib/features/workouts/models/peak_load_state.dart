import 'package:flutter/widgets.dart';
import 'package:lifter/features/workouts/models/workout_phases.dart';

@immutable
class PeakLoadState {
  final Phase phase;
  final Hand currentHand;
  final Hand startingHand;
  final double bodyWeight;
  final int restSeconds;
  
  // The endless loop tracking
  final int repCount; 
  final double currentTarget;
  
  // Tracking max values
  final double leftMax;
  final double rightMax;
  final double currentRepMax; // Tracks max within the current 7s window
  
  // Hand states
  final bool isLeftStopped;
  final bool isRightStopped;
  
  // Timers
  final int secondsRemaining;
  final int currentPhaseDuration;

  const PeakLoadState({
    this.phase = Phase.idle,
    this.currentHand = Hand.left,
    this.startingHand = Hand.left,
    this.bodyWeight = 70.0,
    this.restSeconds = 120,
    this.repCount = 0,
    this.currentTarget = 0.0,
    this.leftMax = 0.0,
    this.rightMax = 0.0,
    this.currentRepMax = 0.0,
    this.isLeftStopped = false,
    this.isRightStopped = false,
    this.secondsRemaining = 0,
    this.currentPhaseDuration = 0,
  });

  int get elapsedSeconds => currentPhaseDuration - secondsRemaining;
  double get phaseProgress => currentPhaseDuration == 0 ? 0 : elapsedSeconds / currentPhaseDuration;

  PeakLoadState copyWith({
    Phase? phase,
    Hand? currentHand,
    Hand? startingHand,
    double? bodyWeight,
    int? restSeconds,
    int? repCount,
    double? currentTarget,
    double? leftMax,
    double? rightMax,
    double? currentRepMax,
    bool? isLeftStopped,
    bool? isRightStopped,
    int? secondsRemaining,
    int? currentPhaseDuration,
  }) {
    return PeakLoadState(
      phase: phase ?? this.phase,
      currentHand: currentHand ?? this.currentHand,
      startingHand: startingHand ?? this.startingHand,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      restSeconds: restSeconds ?? this.restSeconds,
      repCount: repCount ?? this.repCount,
      currentTarget: currentTarget ?? this.currentTarget,
      leftMax: leftMax ?? this.leftMax,
      rightMax: rightMax ?? this.rightMax,
      currentRepMax: currentRepMax ?? this.currentRepMax,
      isLeftStopped: isLeftStopped ?? this.isLeftStopped,
      isRightStopped: isRightStopped ?? this.isRightStopped,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      currentPhaseDuration: currentPhaseDuration ?? this.currentPhaseDuration,
    );
  }
}
