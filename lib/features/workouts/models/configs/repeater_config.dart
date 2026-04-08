import 'package:flutter/material.dart';
import 'package:lifter/features/workouts/models/base_models.dart';

@immutable
class RepeaterConfig {
  final int sets;
  final int reps;
  final int workSeconds;
  final int restSeconds;
  final int setRestSeconds;
  final Hand startingHand;
  
  final int relativeTo; 
  final int targetPercentage;
  final double customWeight;

  const RepeaterConfig({
    this.sets = 3,
    this.reps = 3,
    this.workSeconds = 7,
    this.restSeconds = 3,
    this.setRestSeconds = 10,
    this.startingHand = Hand.left,
    this.relativeTo = 0,
    this.targetPercentage = 50,
    this.customWeight = 0,

  });

  RepeaterConfig copyWith({
    int? sets,
    int? reps,
    int? workSeconds,
    int? restSeconds,
    int? setRestSeconds,
    Hand? startingHand,
    int? relativeTo,
    int? targetPercentage,
    double? customWeight,
  }) {
    return RepeaterConfig(
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      workSeconds: workSeconds ?? this.workSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      setRestSeconds: setRestSeconds ?? this.setRestSeconds,
      startingHand: startingHand ?? this.startingHand,
      relativeTo: relativeTo ?? this.relativeTo,
      targetPercentage: targetPercentage ?? this.targetPercentage,
      customWeight: customWeight ?? this.customWeight,
    );
  }
}
