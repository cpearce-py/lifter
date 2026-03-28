import 'package:flutter/cupertino.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:lifter/features/history/repositories/workout_repository.dart';

class LocalWorkoutRepository implements WorkoutRepository {
  final Database db;

  LocalWorkoutRepository(this.db);

  @override
  Future<void> saveWorkout(WorkoutLog log) async {
    debugPrint("Local DB saving: $log");
    return;
    await db.transaction((txn) async {
      
      final workoutId = await txn.insert(
        'workout', // Table name from your friend's ERD
        {
          'workout_type_id': log.workoutTypeId,
          'user_id': 1, // TODO: Assuming a single local user for now
          'date_done': log.dateDone.toIso8601String(), // SQLite stores dates as ISO strings
          'duration': log.duration,
          'working_time': log.workingTime,
          'notes': log.notes,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Loop through and insert every Set
      for (var s = 0; s < log.sets.length; s++) {
        final setLog = log.sets[s];
        
        final setId = await txn.insert(
          'set', // Table name from ERD
          {
            'workout_id': workoutId, // Link back to the parent workout
            // ERD Note: If Arnaud adds a 'set_number' column, we pass `s + 1` here!
          },
        );

        // 3. Loop through and insert every Repetition inside this Set
        for (var r = 0; r < setLog.repetitions.length; r++) {
          final repLog = setLog.repetitions[r];
          
          await txn.insert(
            'repetition', // Table name from ERD
            {
              'set_id': setId, // Link back to the parent set
              'peak_load_left': repLog.peakLoadLeft,
              'peak_load_right': repLog.peakLoadRight,
            },
          );
        }
      }
    });
  }

  @override
  Future<List<WorkoutLog>> getAllWorkouts() async {
    throw UnimplementedError('Reading workouts coming soon!');
  }

  @override
  Future<WorkoutLog?> getWorkoutById(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteWorkout(int id) async {
    // Because of foreign keys, deleting the workout will cascade and delete its sets/reps
    await db.delete('workout', where: 'workout_id = ?', whereArgs: [id]);
  }
}
