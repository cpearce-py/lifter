import 'dart:typed_data';

import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/models/workout_query_filter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:lifter/features/history/repositories/workout_repository.dart';
import 'package:lifter/features/user/models/user_profile.dart';
import 'package:lifter/features/workouts/models/grip.dart';

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
          'user_id': localUserId,
          'date_done': log.dateDone
              .toIso8601String(), // SQLite stores dates as ISO strings
          'duration': log.duration,
          'working_time': log.workingTime,
          'notes': log.notes,
          'graph_data': log.graphData,
          'template_id': log.templateId,
          'template_name': log.templateName,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _insertSets(txn, workoutId, log.sets);
    });
  }

  Future<void> _insertSets(
    Transaction txn,
    int workoutId,
    List<SetLog> sets,
  ) async {
    // 2. Loop through and insert every Set
    for (var s = 0; s < sets.length; s++) {
      final setLog = sets[s];

      final setId = await txn.insert(
        'set', // Table name from ERD
        {
          'workout_id': workoutId, // Link back to the parent workout
          // ERD Note: If Arnaud adds a 'set_number' column, we pass `s + 1` here!
          'is_warmup': setLog.isWarmup ? 1 : 0,
          'block_name': setLog.blockName,
          'block_index': setLog.blockIndex,
          ...setLog.grip.toMap(),
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
            'average_load_left': repLog.averageLoadLeft,
            'average_load_right': repLog.averageLoadRight,
          },
        );
      }
    }
  }

  @override
  Future<void> updateWorkout(WorkoutLog log) async {
    await db.transaction((txn) async {
      await txn.update(
        'workout',
        {
          'workout_type_id': log.workoutTypeId,
          'date_done': log.dateDone.toIso8601String(),
          'duration': log.duration,
          'working_time': log.workingTime,
          'notes': log.notes,
          'template_name': log.templateName,
        },
        where: 'workout_id = ?',
        whereArgs: [log.id],
      );

      // Sets have no ids of their own, so replace them all. Their reps go
      // with them through the cascade.
      await txn.delete('set', where: 'workout_id = ?', whereArgs: [log.id]);
      await _insertSets(txn, log.id!, log.sets);
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
      columns: [
        'workout_id', 'workout_type_id', 'date_done', 
        'duration', 'working_time', 'notes', 'template_id', 'template_name'
      ],
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
        graphData: null,
        sets: [], // Empty for now
        templateId: row['template_id'] as int?,
        templateName: row['template_name'] as String?,
      );
    }

    // --- STEP 3: Fetch the children (Sets & Reps) for ONLY these Workouts ---
    // Grab the IDs we just fetched: e.g., (14, 15, 16)
    final workoutIds = workoutsMap.keys.toList();
    final placeholders = List.filled(workoutIds.length, '?').join(',');

    final List<Map<String, dynamic>> childrenRows = await db.rawQuery('''
      SELECT 
        s.workout_id, s.set_id, s.is_warmup, s.block_name, s.block_index,
        s.grip, s.edge_mm,
        r.rep_id, r.peak_load_left, r.peak_load_right,
        r.average_load_left, r.average_load_right
      FROM "set" s
      LEFT JOIN repetition r ON s.set_id = r.set_id
      WHERE s.workout_id IN ($placeholders)
      ORDER BY s.workout_id DESC, s.set_id ASC, r.rep_id ASC
    ''', workoutIds);

    // --- STEP 4: Assemble the Nested Objects ---
    final Map<int, Map<int, SetLog>> setsByWorkout = {};

    for (final row in childrenRows) {
      final wId = row['workout_id'] as int;
      final sId = row['set_id'] as int;
      final repLeft = row['peak_load_left'] as double?;

      setsByWorkout.putIfAbsent(wId, () => {});
      setsByWorkout[wId]!.putIfAbsent(sId, () => _setFromRow(row));

      if (repLeft != null) {
        setsByWorkout[wId]![sId]!.repetitions.add(
          RepetitionLog(
            setLogId: sId,
            peakLoadLeft: repLeft,
            peakLoadRight: row['peak_load_right'] as double,
            averageLoadLeft: row['average_load_left'] as double? ?? 0.0,
            averageLoadRight: row['average_load_right'] as double? ?? 0.0,
          ),
        );
      }
    }

    // --- STEP 5: Attach the Sets to the Workouts ---
    final List<WorkoutLog> finalResults = [];

    // Iterate over the original workoutRows so we keep the exact sorting/pagination order!
    for (final row in workoutRows) {
      final wId = row['workout_id'] as int;
      var workout = workoutsMap[wId]!;

      final setsForThisWorkout = setsByWorkout[wId] ?? {};
      final assembledSets = setsForThisWorkout.values.toList();

      finalResults.add(workout.copyWith(sets: assembledSets));
    }

    return finalResults;
  }

  @override
  Future<WorkoutLog?> getWorkoutById(int id) async {
    // 1. Fetch the single workout, this time INLCUDING the BLOB
    final List<Map<String, dynamic>> workoutRows = await db.query(
      'workout',
      where: 'workout_id = ?',
      whereArgs: [id],
    );

    if (workoutRows.isEmpty) return null;
    final row = workoutRows.first;

    // 2. Fetch all sets and reps for this specific workout
    final List<Map<String, dynamic>> childrenRows = await db.rawQuery('''
      SELECT 
        s.set_id, s.is_warmup, s.block_name, s.block_index, s.grip, s.edge_mm,
        r.rep_id, r.peak_load_left, r.peak_load_right,
        r.average_load_left, r.average_load_right
      FROM "set" s
      LEFT JOIN repetition r ON s.set_id = r.set_id
      WHERE s.workout_id = ?
      ORDER BY s.set_id ASC, r.rep_id ASC
    ''', [id]);

    final Map<int, SetLog> setsMap = {};
    for (final child in childrenRows) {
      final sId = child['set_id'] as int;
      final repLeft = child['peak_load_left'] as double?;

      setsMap.putIfAbsent(sId, () => _setFromRow(child));

      if (repLeft != null) {
        setsMap[sId]!.repetitions.add(
          RepetitionLog(
            peakLoadLeft: repLeft,
            peakLoadRight: child['peak_load_right'] as double,
            averageLoadLeft: child['average_load_left'] as double? ?? 0.0,
            averageLoadRight: child['average_load_right'] as double? ?? 0.0,
          ),
        );
      }
    }

    final assembledSets = setsMap.values.toList();

    return WorkoutLog(
      id: id,
      workoutTypeId: row['workout_type_id'] as int,
      dateDone: DateTime.parse(row['date_done'] as String),
      duration: row['duration'] as int,
      workingTime: row['working_time'] as int,
      notes: row['notes'] as String? ?? '',
      graphData: row['graph_data'] as Uint8List?, // Load the heavy graph data!
      sets: assembledSets,
      templateId: row['template_id'] as int?,
      templateName: row['template_name'] as String?,
    );
  }

  // Builds an empty, growable SetLog from a joined set/repetition row.
  SetLog _setFromRow(Map<String, dynamic> row) {
    return SetLog(
      repetitions: [],
      isWarmup: (row['is_warmup'] as int? ?? 0) == 1,
      blockName: row['block_name'] as String?,
      blockIndex: row['block_index'] as int?,
      grip: GripSetup.fromMap(row),
    );
  }

  @override
  Future<void> deleteWorkout(int id) async {
    // Because of foreign keys, deleting the workout will cascade and delete its sets/reps
    await db.delete('workout', where: 'workout_id = ?', whereArgs: [id]);
  }

  @override
  Future<void> updateWorkoutNote(int workoutId, String note) async {
    await db.update(
      'workout',
      {'notes': note},
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
  }
}
