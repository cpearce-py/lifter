
class RepetitionLog {
  final double peakLoadLeft;
  final double peakLoadRight;

  RepetitionLog({
    required this.peakLoadLeft,
    required this.peakLoadRight,
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

  WorkoutLog({
    this.id,
    required this.workoutTypeId,
    required this.dateDone,
    required this.duration,
    required this.workingTime,
    required this.sets,
    this.notes = "",
  });

  WorkoutLog copyWith({
    int? id,
    int? workoutTypeId,
    DateTime? dateDone,
    int? duration,
    int? workingTime,
    List<SetLog>? sets,
    String? notes,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      workoutTypeId: workoutTypeId ?? this.workoutTypeId,
      dateDone: dateDone ?? this.dateDone,
      duration: duration ?? this.duration,
      workingTime: workingTime ?? this.workingTime,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }
}
