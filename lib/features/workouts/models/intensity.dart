import 'dart:math' as math;

import 'package:lifter/features/user/models/user_profile.dart';

/// Labels for the "Relative to" dropdown. The index is what gets stored.
const relativeToLabels = ['Bodyweight', 'Max Lift', 'Custom'];

class RelativeTo {
  static const int bodyweight = 0;
  static const int maxPull = 1;
  static const int custom = 2;
}

/// Resolves a "relative to" selection into a concrete reference weight in kg.
double resolveReferenceWeight({
  required int relativeTo,
  required UserSettings settings,
  required double customWeight,
}) {
  final maxPull = [
    settings.maxPullLeft,
    settings.maxPullRight,
    settings.bodyWeight,
  ].reduce(math.max);

  return switch (relativeTo) {
    RelativeTo.bodyweight => settings.bodyWeight,
    RelativeTo.maxPull => maxPull,
    RelativeTo.custom => customWeight,
    _ => settings.bodyWeight,
  };
}
