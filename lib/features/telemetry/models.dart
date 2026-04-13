import 'package:lifter/features/history/models/log_models.dart';

class WorkoutStats {
  final double maxLeft;
  final double maxRight;
  final double avgLeft;
  final double avgRight;
  final double balanceLeftPct;
  final double balanceRightPct;
  final List<RepetitionLog> flatReps; // Flattens all sets into one timeline

  WorkoutStats({
    required this.maxLeft,
    required this.maxRight,
    required this.avgLeft,
    required this.avgRight,
    required this.balanceLeftPct,
    required this.balanceRightPct,
    required this.flatReps,
  });

  factory WorkoutStats.fromWorkout(WorkoutLog workout) {
    List<RepetitionLog> reps = [];
    double totalLeft = 0;
    double totalRight = 0;
    double mxLeft = 0;
    double mxRight = 0;

    for (final set in workout.sets) {
      for (final rep in set.repetitions) {
        reps.add(rep);
        totalLeft += rep.peakLoadLeft;
        totalRight += rep.peakLoadRight;
        if (rep.peakLoadLeft > mxLeft) mxLeft = rep.peakLoadLeft;
        if (rep.peakLoadRight > mxRight) mxRight = rep.peakLoadRight;
      }
    }

    int count = reps.isEmpty ? 1 : reps.length; // Prevent divide by zero
    double totalCombined = totalLeft + totalRight;
    
    return WorkoutStats(
      maxLeft: mxLeft,
      maxRight: mxRight,
      avgLeft: totalLeft / count,
      avgRight: totalRight / count,
      flatReps: reps,
      // If no weight was pulled, default to 50/50 balance
      balanceLeftPct: totalCombined > 0 ? (totalLeft / totalCombined) : 0.5,
      balanceRightPct: totalCombined > 0 ? (totalRight / totalCombined) : 0.5,
    );
  }
}
