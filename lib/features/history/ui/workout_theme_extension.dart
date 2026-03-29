import 'package:flutter/material.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

extension WorkoutLogTheme on WorkoutLog {
  
  // Dynamically returns the name based on the DB ID
  String get uiTitle {
    switch (workoutTypeId) {
      case 1: return 'Repeater';
      case 2: return 'Peak Load';
      default: return 'Workout';
    }
  }

  // Dynamically returns the brand color based on the DB ID
  Color get uiAccentColor {
    switch (workoutTypeId) {
      case 1: return AppColors.repeaterAccent;
      case 2: return AppColors.peakLoadAccent;
      default: return Colors.white;
    }
  }
  
  // You can even add icons!
  IconData get uiIcon {
    switch (workoutTypeId) {
      case 1: return Icons.repeat_rounded;
      case 2: return Icons.monitor_weight_rounded;
      default: return Icons.fitness_center_rounded;
    }
  }
}
