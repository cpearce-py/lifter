import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/database/database_service.dart';
import 'package:lifter/features/history/repositories/local_workout_repository.dart';
import 'package:lifter/features/history/repositories/workout_repository.dart';
import 'package:lifter/features/workouts/repositories/local_template_repository.dart';
import 'package:lifter/features/workouts/repositories/template_repository.dart';
import 'package:sqflite/sqflite.dart';

// 1. Provide the raw SQLite database connection
final databaseProvider = FutureProvider<Database>((ref) async {
  return await DatabaseService.instance.database;
});

// 2. Provide the repository
final workoutRepositoryProvider = FutureProvider<WorkoutRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  // TODO: To swap to an API later, just change this to:
  // return ApiWorkoutRepository(apiClient);
  return LocalWorkoutRepository(db);
});

// 3. Provide the custom workout template repository
final templateRepositoryProvider = FutureProvider<TemplateRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return LocalTemplateRepository(db);
});
