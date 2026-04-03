import 'package:flutter/material.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

class WorkoutId {
  static const int repeater = 1;
  static const int peakLoad = 2;
}

extension WorkoutLogTheme on WorkoutLog {
  
  // Dynamically returns the name based on the DB ID
  String get uiTitle {
    switch (workoutTypeId) {
      case WorkoutId.repeater: return 'Repeater';
      case WorkoutId.peakLoad: return 'Peak Load';
      default: return 'Workout';
    }
  }

  // Dynamically returns the brand color based on the DB ID
  Color get uiAccentColor {
    switch (workoutTypeId) {
      case WorkoutId.repeater: return AppColors.repeaterAccent;
      case WorkoutId.peakLoad: return AppColors.peakLoadAccent;
      default: return Colors.white;
    }
  }
  
  // You can even add icons!
  IconData get uiIcon {
    switch (workoutTypeId) {
      case WorkoutId.repeater: return Icons.repeat_rounded;
      case WorkoutId.peakLoad: return Icons.monitor_weight_rounded;
      default: return Icons.fitness_center_rounded;
    }
  }
}
