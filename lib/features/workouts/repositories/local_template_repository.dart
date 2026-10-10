import 'package:flutter/foundation.dart';
import 'package:lifter/features/workouts/models/custom/workout_template.dart';
import 'package:lifter/features/workouts/repositories/template_repository.dart';
import 'package:sqflite/sqflite.dart';

class LocalTemplateRepository implements TemplateRepository {
  final Database db;

  LocalTemplateRepository(this.db);

  @override
  Future<List<WorkoutTemplate>> getTemplates() async {
    final templateRows = await db.query(
      'workout_template',
      orderBy: 'template_id ASC',
    );
    if (templateRows.isEmpty) return [];

    final blockRows = await db.query(
      'template_block',
      orderBy: 'template_id ASC, position ASC',
    );

    final Map<int, List<WorkoutBlock>> blocksByTemplate = {};
    for (final row in blockRows) {
      blocksByTemplate
          .putIfAbsent(row['template_id'] as int, () => [])
          .add(WorkoutBlock.fromMap(row));
    }

    return templateRows.map((row) {
      final id = row['template_id'] as int;
      return WorkoutTemplate.fromMap(row, blocksByTemplate[id] ?? []);
    }).toList();
  }

  @override
  Future<WorkoutTemplate?> getTemplateById(int id) async {
    final rows = await db.query(
      'workout_template',
      where: 'template_id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;

    final blockRows = await db.query(
      'template_block',
      where: 'template_id = ?',
      whereArgs: [id],
      orderBy: 'position ASC',
    );

    return WorkoutTemplate.fromMap(
      rows.first,
      blockRows.map(WorkoutBlock.fromMap).toList(),
    );
  }

  @override
  Future<int> saveTemplate(WorkoutTemplate template) {
    return db.transaction((txn) => _writeTemplate(txn, template));
  }

  @override
  Future<void> deleteTemplate(int id) async {
    // Blocks are removed by ON DELETE CASCADE.
    await db.delete('workout_template', where: 'template_id = ?', whereArgs: [id]);
  }

  /// Called from the V3 migration, so it takes the raw executor.
  static Future<void> seedStarterTemplates(DatabaseExecutor db) async {
    for (final template in starterTemplates) {
      await _writeTemplate(db, template);
    }
    debugPrint("Seeded ${starterTemplates.length} starter templates");
  }

  // Blocks are rewritten wholesale on every save; that keeps reordering and
  // deleting blocks simple.
  static Future<int> _writeTemplate(
    DatabaseExecutor db,
    WorkoutTemplate template,
  ) async {
    int templateId;
    if (template.id == null) {
      templateId = await db.insert('workout_template', template.toMap());
    } else {
      templateId = template.id!;
      await db.update(
        'workout_template',
        template.toMap(),
        where: 'template_id = ?',
        whereArgs: [templateId],
      );
      await db.delete(
        'template_block',
        where: 'template_id = ?',
        whereArgs: [templateId],
      );
    }

    for (var i = 0; i < template.blocks.length; i++) {
      await db.insert(
        'template_block',
        template.blocks[i].toMap(templateId: templateId, position: i),
      );
    }

    return templateId;
  }
}
