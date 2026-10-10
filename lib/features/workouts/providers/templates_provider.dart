import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/repository_providers.dart';
import 'package:lifter/features/workouts/models/custom/workout_template.dart';

final templatesProvider =
    AsyncNotifierProvider<TemplatesNotifier, List<WorkoutTemplate>>(
  TemplatesNotifier.new,
);

class TemplatesNotifier extends AsyncNotifier<List<WorkoutTemplate>> {
  @override
  Future<List<WorkoutTemplate>> build() async {
    final repo = await ref.watch(templateRepositoryProvider.future);
    return repo.getTemplates();
  }

  Future<int> saveTemplate(WorkoutTemplate template) async {
    final repo = await ref.read(templateRepositoryProvider.future);
    final id = await repo.saveTemplate(template);
    ref.invalidateSelf();
    return id;
  }

  Future<void> deleteTemplate(int id) async {
    final repo = await ref.read(templateRepositoryProvider.future);
    await repo.deleteTemplate(id);
    ref.invalidateSelf();
  }

  Future<void> duplicateTemplate(WorkoutTemplate template) async {
    await saveTemplate(template.duplicate());
  }
}
