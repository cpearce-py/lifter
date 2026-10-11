import 'package:flutter/material.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/grip.dart';

@immutable
class PeakLoadConfig {
  final double bodyWeight;
  final int restSeconds;
  final Hand startingHand;
  final GripSetup grip;

  const PeakLoadConfig({
    required this.bodyWeight,
    this.restSeconds = 120,
    this.startingHand = Hand.left,
    this.grip = GripSetup.none,
  });

  PeakLoadConfig copyWith({
    double? bodyWeight,
    int? restSeconds,
    Hand? startingHand,
    GripSetup? grip,
  }) {
    return PeakLoadConfig(
      bodyWeight: bodyWeight ?? this.bodyWeight,
      restSeconds: restSeconds ?? this.restSeconds,
      startingHand: startingHand ?? this.startingHand,
      grip: grip ?? this.grip,
    );
  }
}
