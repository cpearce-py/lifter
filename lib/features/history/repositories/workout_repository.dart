import 'package:lifter/features/history/models/log_models.dart';

abstract class WorkoutRepository {
  Future<void> saveWorkout(WorkoutLog log);
  Future<List<WorkoutLog>> getAllWorkouts();
  Future<WorkoutLog?> getWorkoutById(int id);
  Future<void> deleteWorkout(int id);
}
