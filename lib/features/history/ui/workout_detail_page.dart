import 'package:flutter/material.dart';
import 'package:lifter/features/history/models/log_models.dart';

class WorkoutDetailPage extends StatelessWidget {
  final WorkoutLog workout;

  const WorkoutDetailPage({super.key, required this.workout});

  String _getWorkoutName(int typeId) {
    if (typeId == 1) return 'Repeater';
    if (typeId == 2) return 'Peak Load';
    if (typeId == 3) return 'Critical Force';
    return 'Workout';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = workout.dateDone.toLocal().toString().split(' ')[0];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getWorkoutName(workout.workoutTypeId)),
        backgroundColor: Colors.transparent,
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
                _StatCube(label: 'Duration', value: '${(workout.duration / 60).floor()}m ${workout.duration % 60}s'),
                _StatCube(label: 'Sets', value: '${workout.sets.length}'),
              ],
            ),
            
            const SizedBox(height: 24),

            // --- 2. Notes Section (Only shows if they wrote something!) ---
            if (workout.notes.isNotEmpty) ...[
              const Text('Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(workout.notes, style: const TextStyle(color: Colors.white, height: 1.4)),
              ),
              const SizedBox(height: 24),
            ],

            // --- 3. The Granular Set/Rep Data ---
            const Text('Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                      Text('SET ${setIndex + 1}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFE8FF47), letterSpacing: 1.2)),
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
                              Text('Rep ${repIndex + 1}', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                              Row(
                                children: [
                                  Text('L: ${rep.peakLoadLeft.toStringAsFixed(1)}kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 16),
                                  Text('R: ${rep.peakLoadRight.toStringAsFixed(1)}kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
      ],
    );
  }
}
