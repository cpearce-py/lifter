import 'package:lifter/features/workouts/models/custom/workout_template.dart';

abstract class TemplateRepository {
  Future<List<WorkoutTemplate>> getTemplates();
  Future<WorkoutTemplate?> getTemplateById(int id);

  /// Inserts when the template has no id, otherwise updates. Returns the id.
  Future<int> saveTemplate(WorkoutTemplate template);
  Future<void> deleteTemplate(int id);
}
