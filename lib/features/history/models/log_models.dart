
import 'package:flutter/services.dart';

class RepetitionLog {
  final int? id; 
  final int? setLogId; // Foreign Key

  // Peak Stats (The absolute max value hit during the rep)
  final double peakLoadLeft;
  final double peakLoadRight;
  
  // Average Stats (The sum of all readings divided by the number of readings)
  final double averageLoadLeft;
  final double averageLoadRight;

  RepetitionLog({
    this.id,
    this.setLogId,
    required this.peakLoadLeft,
    required this.peakLoadRight,
    required this.averageLoadLeft,
    required this.averageLoadRight,
  });
}

class SetLog {
  final List<RepetitionLog> repetitions;

  SetLog({
    required this.repetitions,
  });
}

class WorkoutLog {
  final int? id;
  final int workoutTypeId; // Maps to workout_type table
  final DateTime dateDone;
  final int duration; // Total seconds
  final int workingTime; // Only seconds spent actually pulling
  final List<SetLog> sets;
  final String notes;
  Uint8List? graphData;

  WorkoutLog({
    this.id,
    required this.workoutTypeId,
    required this.dateDone,
    required this.duration,
    required this.workingTime,
    required this.sets,
    this.notes = "",
    required this.graphData,
  });

  WorkoutLog copyWith({
    int? id,
    int? workoutTypeId,
    DateTime? dateDone,
    int? duration,
    int? workingTime,
    List<SetLog>? sets,
    String? notes,
    Uint8List? graphData,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      workoutTypeId: workoutTypeId ?? this.workoutTypeId,
      dateDone: dateDone ?? this.dateDone,
      duration: duration ?? this.duration,
      workingTime: workingTime ?? this.workingTime,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      graphData: graphData ?? this.graphData,
    );
  }
}
