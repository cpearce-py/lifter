import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/measurements/widgets/weight_text.dart';
import 'package:lifter/core/providers/history_provider.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/telemetry/models.dart';
import 'package:lifter/features/telemetry/ui/charts/rep_progression_chart.dart';
import 'package:lifter/features/telemetry/ui/widgets/asymmetry_balance_bar.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_notes.dart';
import 'package:lifter/features/history/ui/workout_theme_extension.dart';

class WorkoutDetailPage extends ConsumerStatefulWidget {
  final WorkoutLog workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  ConsumerState<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends ConsumerState<WorkoutDetailPage> {
  late TextEditingController _notesController;
  bool _isDirty = false;
  bool _isSaving = false;
  late String _oldNote;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.workout.notes);
    _oldNote = widget.workout.notes;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (widget.workout.id == null) return;

    setState(() {
      _isSaving = true;
    });
    await ref.read(workoutHistoryProvider.notifier).updateWorkoutNote(
      widget.workout.id!,
      _notesController.text.trim(),
    );

    setState(() {
      _isSaving = false;
      _isDirty = false; // Hide the save button again
      _oldNote = _notesController.text.trim();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note updated!'),
          backgroundColor: context.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
    context: context, 
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E24),
      title: const Text("Delete workout?", style: TextStyle(color: Colors.white)),
      content: const Text('This will permanently delete this workout and all of its sets. This cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      )
    );
    if (confirmed == true && widget.workout.id != null) {
      await ref.read(workoutHistoryProvider.notifier).deleteWorkout(widget.workout.id!);
      // Pop back to the History list!
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // THE CARD FACTORY: Decides what graphs to show based on the workout type!
  List<Widget> _buildWorkoutCards(BuildContext context, WorkoutStats stats) {
    final List<Widget> cards = [];

    // 1. Everyone gets the Asymmetry Balance Bar
    cards.add(
      Card(
        elevation: 0,
        color: context.cardBackground, // Use your app's surface color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AsymmetryBalanceBar(stats: stats),
        ),
      ),
    );

    cards.add(const SizedBox(height: 16));

    // 2. Add specific charts based on what kind of workout this was!
    if (widget.workout.workoutTypeId == 1) { // Example: 1 = Repeater
      cards.add(
        Card(
          elevation: 0,
          color: context.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: RepProgressionChart(stats: stats),
          ),
        ),
      );
    } else if (widget.workout.workoutTypeId == 2) { // Example: 2 = Max Pull
      cards.add(
        Card(
          elevation: 0,
          color: context.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: RepProgressionChart(stats: stats), 
            // Note: A line chart still looks great for Max Pulls to see warm-up progression!
          ),
        ),
      );
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;
    final dateStr = workout.dateDone.toLocal().toString().split(' ')[0];

    final stats = WorkoutStats.fromWorkout(workout);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          workout.uiTitle,
          style: context.h1,
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _confirmDelete(context), 
            icon: Icon(Icons.delete_outline, color: Colors.redAccent))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Top Level Stats ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCube(label: 'Date', value: dateStr),
                _StatCube(
                  label: 'Duration',
                  value:
                      '${(workout.duration / 60).floor()}m ${workout.duration % 60}s',
                ),
                _StatCube(label: 'Sets', value: '${workout.sets.length}'),
              ],
            ),

            const SizedBox(height: 24),

            // --- Notes Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textMuted,
                  ),
                ),
                // Save button, turn on if we're dirty.
                SizedBox(
                  height: 48,
                  width: 100,
                  child: AnimatedOpacity(
                    opacity: _isDirty ? 1.0 : 0.0, 
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_isDirty,
                      child: Center(
                        child:
                        _isSaving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                          : TextButton(onPressed: _saveNote,
                          child: Text(
                            "Save Note", 
                            style: TextStyle(
                              color: context.peakLoadAccent, 
                              fontWeight: FontWeight.bold))
                            )
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            WorkoutNotesField(
              controller: _notesController,
              onChanged: (text) {
                // If the text differs from the original DB string, show the save button
                final isDifferent = text.trim() != _oldNote;
                if (isDifferent && !_isDirty) {
                  setState(() => _isDirty = true);
                } else if (!isDifferent && _isDirty) {
                  setState(() => _isDirty = false);
                }
              },
            ),
            const SizedBox(height: 24),

            Text(
              'Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            
            // This cleanly unpacks the balance bar and line charts!
            ..._buildWorkoutCards(context, stats),
            
            const SizedBox(height: 24),

            // --- 3. The Granular Set/Rep Data ---
            Text(
              'Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textMuted,
              ),
            ),
            const SizedBox(height: 12),

            ...workout.sets.asMap().entries.map((entry) {
              final setIndex = entry.key;
              final setLog = entry.value;

              return Card(
                color: context.cardBackground,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SET ${setIndex + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: workout.uiAccentColor(context),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Loop through the reps in this set
                      ...setLog.repetitions.asMap().entries.map((repEntry) {
                        final repIndex = repEntry.key;
                        final rep = repEntry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Rep ${repIndex + 1}',
                                style: TextStyle(
                                  color: context.textMuted,
                                ),
                              ),
                              Row(
                                children: [
                                  WeightText(
                                    prefix: "L: ",
                                    weightKg: rep.peakLoadLeft,
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  WeightText(
                                    prefix: "R: ",
                                    weightKg: rep.peakLoadRight,
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// A cute little helper widget for the top stats
class _StatCube extends StatelessWidget {
  final String label;
  final String value;
  const _StatCube({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.textMuted),
        ),
      ],
    );
  }
}
