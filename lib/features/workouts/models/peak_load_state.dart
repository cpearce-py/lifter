import 'package:flutter/material.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/workouts/models/base_models.dart';

@immutable
class PeakLoadState {
  // --- Core State ---
  final Phase phase;
  
  // --- Workout Configuration ---
  final double bodyWeight;
  final int restSeconds;
  final Hand startingHand;
  
  // --- Endless Loop Progress ---
  final Hand currentHand;
  final int repCount; 
  final double currentTarget;
  
  // --- Max Value Tracking ---
  final double leftMax;
  final double rightMax;
  final double currentRepMax; // Tracks the max reading during the active 7-second window
  final List<SetLog> completedSets;

  final double currentRepSum;
  final int currentRepCount;
  final double leftAvg;
  final double rightAvg;
  
  // --- Branching Logic (Skipped Hands) ---
  final bool isLeftStopped;
  final bool isRightStopped;
  
  // --- Timers ---
  final int secondsRemaining;
  final int currentPhaseDuration;

  const PeakLoadState({
    this.phase = Phase.idle,
    this.bodyWeight = 70.0, // Default to a sensible weight, but overridden by the config UI
    this.restSeconds = 120, // e.g., 2 minutes rest between rounds
    this.startingHand = Hand.left,
    this.currentHand = Hand.left,
    this.repCount = 0,
    this.currentTarget = 0.0,
    this.leftMax = 0.0,
    this.rightMax = 0.0,
    this.currentRepMax = 0.0,
    this.isLeftStopped = false,
    this.isRightStopped = false,
    this.secondsRemaining = 0,
    this.currentPhaseDuration = 0,
    this.completedSets = const [],
    this.currentRepSum = 0,
    this.currentRepCount = 0,
    this.leftAvg = 0.0,
    this.rightAvg = 0.0,
  });

  // --- UI Helpers ---
  
  int get elapsedSeconds => currentPhaseDuration - secondsRemaining;
  
  double get phaseProgress {
    if (currentPhaseDuration == 0) return 0.0;
    return elapsedSeconds / currentPhaseDuration;
  }

  // --- Immutability ---

  PeakLoadState copyWith({
    Phase? phase,
    double? bodyWeight,
    int? restSeconds,
    Hand? startingHand,
    Hand? currentHand,
    int? repCount,
    double? currentTarget,
    double? leftMax,
    double? rightMax,
    double? currentRepMax,
    bool? isLeftStopped,
    bool? isRightStopped,
    int? secondsRemaining,
    int? currentPhaseDuration,
    List<SetLog>? completedSets,
    double? currentRepSum,
    int? currentRepCount,
    double? leftAvg,
    double? rightAvg,
  }) {
    return PeakLoadState(
      phase: phase ?? this.phase,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      restSeconds: restSeconds ?? this.restSeconds,
      startingHand: startingHand ?? this.startingHand,
      currentHand: currentHand ?? this.currentHand,
      repCount: repCount ?? this.repCount,
      currentTarget: currentTarget ?? this.currentTarget,
      leftMax: leftMax ?? this.leftMax,
      rightMax: rightMax ?? this.rightMax,
      currentRepMax: currentRepMax ?? this.currentRepMax,
      isLeftStopped: isLeftStopped ?? this.isLeftStopped,
      isRightStopped: isRightStopped ?? this.isRightStopped,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      currentPhaseDuration: currentPhaseDuration ?? this.currentPhaseDuration,
      completedSets: completedSets ?? this.completedSets,
      currentRepSum: currentRepSum ?? this.currentRepSum,
      currentRepCount: currentRepCount ?? this.currentRepCount,
      leftAvg: leftAvg ?? this.leftAvg,
      rightAvg: rightAvg ?? this.rightAvg,
    );
  }
}
