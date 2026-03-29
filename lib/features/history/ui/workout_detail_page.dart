import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/history_provider.dart';
import 'package:lifter/features/history/models/log_models.dart';
import './helpers.dart';

class WorkoutDetailPage extends ConsumerWidget {
  final WorkoutLog workout;

  const WorkoutDetailPage({super.key, required this.workout});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
    if (confirmed == true && workout.id != null) {
      await ref.read(workoutHistoryProvider.notifier).deleteWorkout(workout.id!);
      // 2. Pop back to the History list!
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = workout.dateDone.toLocal().toString().split(' ')[0];

    return Scaffold(
      appBar: AppBar(
        title: Text(getWorkoutName(workout.workoutTypeId)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _confirmDelete(context, ref), 
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

            // --- 2. Notes Section (Only shows if they wrote something!) ---
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    workout.notes,
                    style: const TextStyle(color: Colors.white, height: 1.4),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit)
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 3. The Granular Set/Rep Data ---
            const Text(
              'Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            ...workout.sets.asMap().entries.map((entry) {
              final setIndex = entry.key;
              final setLog = entry.value;

              return Card(
                color: Colors.white.withOpacity(0.03),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SET ${setIndex + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE8FF47),
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
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'L: ${rep.peakLoadLeft.toStringAsFixed(1)}kg',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'R: ${rep.peakLoadRight.toStringAsFixed(1)}kg',
                                    style: const TextStyle(
                                      color: Colors.white,
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
        ),
      ],
    );
  }
}
