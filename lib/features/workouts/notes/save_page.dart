import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:lifter/core/providers/history_provider.dart';
import 'package:lifter/core/providers/repository_providers.dart';
import 'package:lifter/core/providers/stats_provider.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/workouts/ui/workout_choice_page.dart';

class SaveWorkoutPage extends ConsumerStatefulWidget {
  final WorkoutLog workoutLog;

  const SaveWorkoutPage({super.key, required this.workoutLog});

  @override
  ConsumerState<SaveWorkoutPage> createState() => _SaveWorkoutPageState();
}

class _SaveWorkoutPageState extends ConsumerState<SaveWorkoutPage> {
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _navigateHome() {
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

  void _save() async {
    setState(() => _isSaving = true);
    try {
      // Add note
      final finalLog = widget.workoutLog.copyWith(
        notes: _notesController.text.trim(),
      );
      
      final repository = await ref.read(workoutRepositoryProvider.future);
      await repository.saveWorkout(finalLog);

      // Invalidate cached states.
      ref.invalidate(workoutHistoryProvider);
      ref.invalidate(userStatsProvider);
      
      _navigateHome();
    } catch (e) {
      debugPrint("Failed to save: $e");
      setState(() => _isSaving = false);
    }
  }

  void _discard() {
    _navigateHome();
  }

  @override
  Widget build(BuildContext context) {
    final workoutLog = widget.workoutLog;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Save Workout', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Generic Workout Summary Card
            Card(
              color: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${workoutLog.workoutTypeId} Complete', 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                    const SizedBox(height: 12),
                    _StatRow(label: 'Duration', value: '${(workoutLog.workingTime / 60).floor()}m ${workoutLog.duration % 60}s'),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notes field
            const Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 5,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'How did it feel?',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const Spacer(),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _discard,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Discard', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE8FF47),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Text('Save Workout', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6))),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
