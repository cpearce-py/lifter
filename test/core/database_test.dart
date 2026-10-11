import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifter/core/database/database_service.dart';
import 'package:lifter/core/providers/history_provider.dart';
import 'package:lifter/core/providers/repository_providers.dart';
import 'package:lifter/features/workouts/providers/weekly_provider.dart';
import 'package:lifter/core/providers/shared_preferences_provider.dart';
import 'package:lifter/features/user/models/user_profile.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';
import 'package:lifter/features/user/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/repositories/local_workout_repository.dart';
import 'package:lifter/features/history/ui/workout_theme_extension.dart';
import 'package:lifter/features/workouts/models/custom/workout_template.dart';
import 'package:lifter/features/workouts/repositories/local_template_repository.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

RepetitionLog rep(double kg) => RepetitionLog(
      peakLoadLeft: kg,
      peakLoadRight: kg,
      averageLoadLeft: kg - 2,
      averageLoadRight: kg - 2,
    );

/// The schema as a V2 install has it: the original tables plus the V2
/// upgrade columns.
Future<void> createV2Database(String path) async {
  final db = await openDatabase(path, version: 2, onCreate: (db, _) async {
    await db.execute('''
      CREATE TABLE user (user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        username VARCHAR(16) NOT NULL, first_name VARCHAR(45),
        last_name VARCHAR(45), email VARCHAR(255),
        max_pull_left REAL DEFAULT 0.0, max_pull_right REAL DEFAULT 0.0,
        create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, update_time DATETIME)
    ''');
    await db.execute('''
      CREATE TABLE workout (workout_id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_type_id INTEGER NOT NULL, user_id INTEGER NOT NULL,
        date_done TEXT NOT NULL, duration INTEGER NOT NULL,
        working_time INTEGER NOT NULL, notes TEXT, graph_data BLOB)
    ''');
    await db.execute('''
      CREATE TABLE "set" (set_id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        FOREIGN KEY (workout_id) REFERENCES workout (workout_id) ON DELETE CASCADE)
    ''');
    await db.execute('''
      CREATE TABLE repetition (rep_id INTEGER PRIMARY KEY AUTOINCREMENT,
        set_id INTEGER NOT NULL, peak_load_left REAL NOT NULL,
        peak_load_right REAL NOT NULL,
        average_load_left REAL DEFAULT 0.0, average_load_right REAL DEFAULT 0.0,
        FOREIGN KEY (set_id) REFERENCES "set" (set_id) ON DELETE CASCADE)
    ''');
    await db.execute('''
      CREATE TABLE workout_type (workout_type_id INTEGER PRIMARY KEY,
        workout_name TEXT NOT NULL)
    ''');
    await db.insert('workout_type', {'workout_type_id': 1, 'workout_name': 'Repeater'});
    await db.insert('workout_type', {'workout_type_id': 2, 'workout_name': 'Peak Load'});
  });

  final workoutId = await db.insert('workout', {
    'workout_type_id': 1,
    'user_id': 1,
    'date_done': DateTime(2026, 9, 1).toIso8601String(),
    'duration': 300,
    'working_time': 120,
    'notes': 'old',
  });
  final setId = await db.insert('set', {'workout_id': workoutId});
  await db.insert('repetition', {
    'set_id': setId,
    'peak_load_left': 20.0,
    'peak_load_right': 21.0,
  });
  await db.close();
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() => DatabaseService.instance.wipeDatabase());
  tearDownAll(() => DatabaseService.instance.wipeDatabase());

  test('fresh install seeds the starter templates', () async {
    final db = await DatabaseService.instance.database;
    final templates = await LocalTemplateRepository(db).getTemplates();

    expect(templates.map((t) => t.name),
        starterTemplates.map((t) => t.name));
    expect(templates.first.blocks.length, starterTemplates.first.blocks.length);
    expect(templates.first.blocks.first.kind, BlockKind.warmup);
    expect(templates.first.blocks.first.endPercentage, 70);
  });

  test('custom workouts round-trip their template and set tags', () async {
    final db = await DatabaseService.instance.database;
    final repo = LocalWorkoutRepository(db);

    await repo.saveWorkout(WorkoutLog(
      workoutTypeId: WorkoutId.custom,
      dateDone: DateTime.now(),
      duration: 600,
      workingTime: 200,
      graphData: Uint8List(0),
      templateId: 1,
      templateName: 'Max Hangs',
      sets: [
        SetLog(repetitions: [rep(10)], isWarmup: true, blockName: 'Warm-up', blockIndex: 0),
        SetLog(repetitions: [rep(30), rep(31)], blockName: 'Max hangs', blockIndex: 1),
      ],
    ));

    final listed = (await repo.getWorkouts()).single;
    final loaded = (await repo.getWorkoutById(listed.id!))!;

    for (final w in [listed, loaded]) {
      expect(w.templateName, 'Max Hangs');
      expect(w.templateId, 1);
      expect(w.sets.map((s) => s.isWarmup), [true, false]);
      expect(w.sets.map((s) => s.blockName), ['Warm-up', 'Max hangs']);
      expect(w.sets.map((s) => s.blockIndex), [0, 1]);
      expect(w.sets.last.repetitions.length, 2);
    }
  });

  test('template save updates, reorders and deletes blocks', () async {
    final db = await DatabaseService.instance.database;
    final repo = LocalTemplateRepository(db);

    final id = await repo.saveTemplate(const WorkoutTemplate(
      name: 'Mine',
      blocks: [WorkoutBlock.warmup(), WorkoutBlock.working()],
    ));
    var saved = (await repo.getTemplateById(id))!;

    await repo.saveTemplate(saved.copyWith(
      name: 'Renamed',
      blocks: saved.blocks.reversed.toList(),
    ));
    saved = (await repo.getTemplateById(id))!;
    expect(saved.name, 'Renamed');
    expect(saved.blocks.map((b) => b.kind), [BlockKind.working, BlockKind.warmup]);

    await repo.deleteTemplate(id);
    expect(await repo.getTemplateById(id), isNull);
    final orphans = await db.query('template_block',
        where: 'template_id = ?', whereArgs: [id]);
    expect(orphans, isEmpty);
  });

  test('upgrading from V2 keeps existing workouts', () async {
    final path = join(await getDatabasesPath(), DatabaseService.dbName);
    await createV2Database(path);

    final db = await DatabaseService.instance.database;
    expect(await db.getVersion(), 4);

    final old = (await LocalWorkoutRepository(db).getWorkouts()).single;
    expect(old.notes, 'old');
    expect(old.templateName, isNull);
    expect(old.sets.single.isWarmup, isFalse);
    expect(old.sets.single.blockName, isNull);
    expect(old.sets.single.repetitions.single.peakLoadRight, 21.0);

    final templates = await LocalTemplateRepository(db).getTemplates();
    expect(templates.length, starterTemplates.length);
  });

  test('repairs databases created without the V2 columns', () async {
    // Before V3, a fresh install ran _createDB, which left these out.
    final path = join(await getDatabasesPath(), DatabaseService.dbName);
    final broken = await openDatabase(path, version: 2, onCreate: (db, _) async {
      await db.execute('CREATE TABLE user (user_id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL, max_pull_left REAL DEFAULT 0.0, max_pull_right REAL DEFAULT 0.0, update_time DATETIME)');
      await db.execute('CREATE TABLE workout (workout_id INTEGER PRIMARY KEY AUTOINCREMENT, workout_type_id INTEGER NOT NULL, user_id INTEGER NOT NULL, date_done TEXT NOT NULL, duration INTEGER NOT NULL, working_time INTEGER NOT NULL, notes TEXT)');
      await db.execute('CREATE TABLE "set" (set_id INTEGER PRIMARY KEY AUTOINCREMENT, workout_id INTEGER NOT NULL)');
      await db.execute('CREATE TABLE repetition (rep_id INTEGER PRIMARY KEY AUTOINCREMENT, set_id INTEGER NOT NULL, peak_load_left REAL NOT NULL, peak_load_right REAL NOT NULL)');
      await db.execute('CREATE TABLE workout_type (workout_type_id INTEGER PRIMARY KEY, workout_name TEXT NOT NULL)');
    });
    await broken.close();

    final db = await DatabaseService.instance.database;
    final repo = LocalWorkoutRepository(db);
    await repo.seedDummyData();

    final workouts = await repo.getWorkouts();
    expect(workouts.length, 3);
    final custom = workouts.firstWhere((w) => w.workoutTypeId == WorkoutId.custom);
    expect(custom.templateName, 'Max Hangs');
    expect(custom.sets.where((s) => s.isWarmup).length, 3);
  });

  test('seeding works after a wipe once the provider is rebuilt', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var repo = await container.read(workoutRepositoryProvider.future);
    await repo.seedDummyData();

    // What the Nuke Database button does.
    await DatabaseService.instance.wipeDatabase();
    container.invalidate(databaseProvider);

    repo = await container.read(workoutRepositoryProvider.future);
    await repo.seedDummyData();
    expect((await repo.getWorkouts()).length, 3);
  });

  test('a new Peak Load best reaches the settings copy', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
    ]);
    addTearDown(container.dispose);

    final db = await container.read(databaseProvider.future);
    await LocalUserRepository(db).saveUser(UserProfile(id: 1, username: 'climber'));
    expect(container.read(userSettingsProvider).maxPullLeft, 0);

    // The seed includes a Peak Load of 25 / 26 kg.
    await LocalWorkoutRepository(db).seedDummyData();
    await container.read(userSettingsProvider.notifier).syncMaxPullsFromDatabase();

    final settings = container.read(userSettingsProvider);
    expect(settings.maxPullLeft, 25.0);
    expect(settings.maxPullRight, 26.0);

    // And it's persisted, not just in memory.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('maxPullRight'), 26.0);
  });

  test('changing the username keeps the max pulls', () async {
    final db = await DatabaseService.instance.database;
    final users = LocalUserRepository(db);
    await users.saveUser(UserProfile(id: 1, username: 'climber'));
    await LocalWorkoutRepository(db).seedDummyData();

    await users.saveUser(UserProfile(id: 1, username: 'renamed'));

    expect((await users.getUser(1))!.username, 'renamed');
    final pulls = await users.getMaxPulls(1);
    expect(pulls.left, 25.0);
    expect(pulls.right, 26.0);
  });

  test('after a wipe, recent workouts and the calendar both read the new database', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Home is open, listening to both.
    final history = container.listen(workoutHistoryProvider, (_, _) {});
    final week = container.listen(weekWorkoutsProvider(0), (_, _) {});
    await container.read(workoutHistoryProvider.notifier).injectDummyData();
    expect((await container.read(workoutHistoryProvider.future)).workouts, isNotEmpty);

    // What Nuke Database does. Note: recent workouts is not invalidated by
    // hand; it has to follow the database like everything else.
    await DatabaseService.instance.wipeDatabase();
    container.invalidate(databaseProvider);

    // Home goes away during onboarding, then comes back.
    history.close();
    week.close();
    await Future<void>.delayed(Duration.zero);
    container.listen(workoutHistoryProvider, (_, _) {});
    container.listen(weekWorkoutsProvider(0), (_, _) {});

    expect((await container.read(workoutHistoryProvider.future)).workouts, isEmpty);
    expect(await container.read(weekWorkoutsProvider(0).future), isEmpty);
  });
}
