import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:lifter/core/providers/workout_provider.dart';
import 'package:lifter/features/workouts/workout_page.dart';

class SaveWorkoutPage extends ConsumerStatefulWidget {
  const SaveWorkoutPage({super.key});

  @override
  ConsumerState<SaveWorkoutPage> createState() => _SaveWorkoutPageState();
}

class _SaveWorkoutPageState extends ConsumerState<SaveWorkoutPage> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _navigateHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const WorkoutPage(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
      );
  }

  void _save() {
    final state = ref.read(workoutNotifierProvider);
    // Save your workout here — e.g. pass to a repository
    final notes = _notesController.text;
    debugPrint('Saving workout: sets=${state.sets}, reps=${state.reps}, notes=$notes');

    // Navigate back to the setup page, clearing the stack
    _navigateHome(context);
  }

  void _discard() {
    ref.read(workoutNotifierProvider.notifier).reset();
    _navigateHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Save Workout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workout summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Workout Complete', 
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Sets: ${state.sets}'),
                    Text('Reps: ${state.reps}'),
                    Text('Work: ${state.workSeconds}s per rep'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notes field
            Text('Notes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'How did it feel?',
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _discard,
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
