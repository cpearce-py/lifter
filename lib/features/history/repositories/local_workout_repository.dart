import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/models/workout_query_filter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:lifter/features/history/repositories/workout_repository.dart';

class LocalWorkoutRepository implements WorkoutRepository {
  final Database db;

  LocalWorkoutRepository(this.db);

  @override
  Future<void> saveWorkout(WorkoutLog log) async {
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
  Future<List<WorkoutLog>> getWorkouts({WorkoutQueryFilter? filter}) async {
    final queryFilter = filter ?? WorkoutQueryFilter();
    
    // --- STEP 1: Build the dynamic WHERE clause for dates ---
    String whereClause = '1=1'; // Dummy true statement to make appending easy
    List<dynamic> whereArgs = [];

    if (queryFilter.startDate != null) {
      whereClause += ' AND date_done >= ?';
      whereArgs.add(queryFilter.startDate!.toIso8601String());
    }
    if (queryFilter.endDate != null) {
      whereClause += ' AND date_done <= ?';
      whereArgs.add(queryFilter.endDate!.toIso8601String());
    }

    // --- STEP 2: Fetch the paginated Workouts ---
    final List<Map<String, dynamic>> workoutRows = await db.query(
      'workout',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date_done DESC',
      limit: queryFilter.limit,
      offset: queryFilter.offset,
    );

    if (workoutRows.isEmpty) return [];

    // Convert the raw rows into our base WorkoutLog objects (without sets yet)
    final Map<int, WorkoutLog> workoutsMap = {};
    for (final row in workoutRows) {
      final id = row['workout_id'] as int;
      workoutsMap[id] = WorkoutLog(
        id: id,
        workoutTypeId: row['workout_type_id'] as int,
        dateDone: DateTime.parse(row['date_done'] as String),
        duration: row['duration'] as int,
        workingTime: row['working_time'] as int,
        notes: row['notes'] as String? ?? '',
        sets: [], // Empty for now
      );
    }

    // --- STEP 3: Fetch the children (Sets & Reps) for ONLY these Workouts ---
    // Grab the IDs we just fetched: e.g., (14, 15, 16)
    final workoutIds = workoutsMap.keys.toList();
    final placeholders = List.filled(workoutIds.length, '?').join(',');

    final List<Map<String, dynamic>> childrenRows = await db.rawQuery('''
      SELECT 
        s.workout_id, s.set_id,
        r.rep_id, r.peak_load_left, r.peak_load_right
      FROM "set" s
      LEFT JOIN repetition r ON s.set_id = r.set_id
      WHERE s.workout_id IN ($placeholders)
      ORDER BY s.workout_id DESC, s.set_id ASC, r.rep_id ASC
    ''', workoutIds);

    // --- STEP 4: Assemble the Nested Objects ---
    final Map<int, Map<int, List<RepetitionLog>>> setsByWorkout = {};

    for (final row in childrenRows) {
      final wId = row['workout_id'] as int;
      final sId = row['set_id'] as int;
      final repLeft = row['peak_load_left'] as double?;
      
      setsByWorkout.putIfAbsent(wId, () => {});
      setsByWorkout[wId]!.putIfAbsent(sId, () => []);

      if (repLeft != null) {
        setsByWorkout[wId]![sId]!.add(RepetitionLog(
          peakLoadLeft: repLeft,
          peakLoadRight: row['peak_load_right'] as double,
        ));
      }
    }

    // --- STEP 5: Attach the Sets to the Workouts ---
    final List<WorkoutLog> finalResults = [];
    
    // Iterate over the original workoutRows so we keep the exact sorting/pagination order!
    for (final row in workoutRows) {
      final wId = row['workout_id'] as int;
      var workout = workoutsMap[wId]!;

      final setsForThisWorkout = setsByWorkout[wId] ?? {};
      final assembledSets = setsForThisWorkout.values.map((reps) => SetLog(repetitions: reps)).toList();
  
      finalResults.add(workout.copyWith(sets: assembledSets));
    }

    return finalResults;
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
