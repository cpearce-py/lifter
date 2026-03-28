class WorkoutSummary {
  final String id;
  final String workoutType; // e.g., 'Repeater', 'PeakLoad'
  final DateTime date;
  final double peakWeight;
  final int totalDurationSeconds;
  final int workSeconds;
  final String notes;

  WorkoutSummary({
    required this.id,
    required this.workoutType,
    required this.date,
    required this.peakWeight,
    required this.totalDurationSeconds,
    required this.workSeconds,
    this.notes = "",
  });

WorkoutSummary copyWith({String? notes}) {
    return WorkoutSummary(
      id: id,
      workoutType: workoutType,
      date: date,
      peakWeight: peakWeight,
      totalDurationSeconds: totalDurationSeconds,
      workSeconds: workSeconds,
      notes: notes ?? this.notes,
    );
  }

  // SQFlite needs Maps to save data
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutType': workoutType,
      'date': date.toIso8601String(),
      'peakWeight': peakWeight,
      'totalDurationSeconds': totalDurationSeconds,
      'workSeconds': workSeconds,
      'notes': notes,
    };
  }

  // Reading from SQFlite
  factory WorkoutSummary.fromMap(Map<String, dynamic> map) {
    return WorkoutSummary(
      id: map['id'] as String,
      workoutType: map['workoutType'] as String,
      date: DateTime.parse(map['date'] as String),
      peakWeight: map['peakWeight'] as double,
      totalDurationSeconds: map['totalDurationSeconds'] as int,
      workSeconds: map['workSeconds'] as int,
      notes: map['notes'] as String? ?? '',
    );
  }
}
