import 'package:flutter/material.dart';

enum OptionType { toggle, stepper, segmented }

class WorkoutType {
  const WorkoutType({
    required this.name,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.options,
    required this.sessionBuilder,
  });

  final String name;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<WorkoutOption> options;

  final Widget Function(Map<int, dynamic>) sessionBuilder;
}

class WorkoutOption {
  const WorkoutOption({
    required this.label,
    required this.type,
    this.choices,
    this.min,
    this.max,
    this.step,
    this.unit,
  });

  final String label;
  final OptionType type;
  final List<String>? choices;  // for segmented
  final num? min;               // for stepper
  final num? max;               // for stepper
  final num? step;              // for stepper
  final String? unit;           // for stepper
}