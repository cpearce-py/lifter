import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:lifter/core/providers/history_provider.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/ui/workout_theme_extension.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_notes.dart';

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
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
  }

  void _save() async {
    setState(() => _isSaving = true);
    try {
      // Add note.
      final finalLog = widget.workoutLog.copyWith(
        notes: _notesController.text.trim(),
      );

      await ref.read(workoutHistoryProvider.notifier).saveWorkout(finalLog);

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
    final accentColor = workoutLog.uiAccentColor(context);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Save Workout',
          style: context.body.copyWith(fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: context.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Generic Workout Summary Card
            Container(
              decoration: BoxDecoration(
                color: context.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.cardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${workoutLog.uiTitle} Complete',
                      style: context.h1.copyWith(
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'Duration',
                      value:
                          '${(workoutLog.workingTime / 60).floor()}m ${workoutLog.duration % 60}s',
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notes field
            Text(
              'Notes',
              style: context.cardTitle.copyWith(
                fontSize: 16,
              )
            ),
            const SizedBox(height: 8),
            WorkoutNotesField(controller: _notesController),

            const Spacer(),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _discard,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: context.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Discard',
                      style: TextStyle(color: context.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: context.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: context.background,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save Workout',
                            style: context.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.background,
                            ),
                          ),
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
        Text(label, style: TextStyle(color: context.textMuted)),
        Text(
          value,
          style: context.body.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
