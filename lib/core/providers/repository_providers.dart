import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/database/database_service.dart';
import 'package:lifter/features/history/repositories/local_workout_repository.dart';
import 'package:lifter/features/history/repositories/workout_repository.dart';
import 'package:sqflite/sqflite.dart';

// 1. Provide the raw SQLite database connection
final databaseProvider = FutureProvider<Database>((ref) async {
  return await DatabaseService.database;
});

// 2. Provide the repository
final workoutRepositoryProvider = FutureProvider<WorkoutRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  // TODO: To swap to an API later, just change this to:
  // return ApiWorkoutRepository(apiClient);
  return LocalWorkoutRepository(db);
});
