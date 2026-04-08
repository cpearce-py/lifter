import 'package:flutter/material.dart';
import 'package:lifter/features/workouts/models/base_models.dart';

@immutable
class PeakLoadConfig {
  final double bodyWeight;
  final int restSeconds;
  final Hand startingHand;

  const PeakLoadConfig({
    required this.bodyWeight,
    this.restSeconds = 120,
    this.startingHand = Hand.left,
  });

  PeakLoadConfig copyWith({
    double? bodyWeight,
    int? restSeconds,
    Hand? startingHand,
  }) {
    return PeakLoadConfig(
      bodyWeight: bodyWeight ?? this.bodyWeight,
      restSeconds: restSeconds ?? this.restSeconds,
      startingHand: startingHand ?? this.startingHand,
    );
  }
}
