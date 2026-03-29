import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/history_provider.dart';
import 'package:lifter/features/history/ui/workout_detail_page.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  // Quick helper to map the DB integer to a readable name
  String _getWorkoutName(int typeId) {
    switch (typeId) {
      case 1: return 'Repeater';
      case 2: return 'Peak Load';
      default: return 'Workout';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFE8FF47))),
        error: (err, stack) => Center(child: Text('Error loading history:\n$err', style: const TextStyle(color: Colors.redAccent))),
        data: (workouts) {
          if (workouts.isEmpty) {
            return Center(
              child: Text(
                'No workouts yet.\n',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              final dateStr = workout.dateDone.toLocal().toString().split(' ')[0]; // Quick YYYY-MM-DD format
              
              return Card(
                color: Colors.white.withOpacity(0.05),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(
                    _getWorkoutName(workout.workoutTypeId),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.white.withOpacity(0.5)),
                        const SizedBox(width: 6),
                        Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.7))),
                        const SizedBox(width: 16),
                        Icon(Icons.timer_outlined, size: 14, color: Colors.white.withOpacity(0.5)),
                        const SizedBox(width: 6),
                        Text('${(workout.duration / 60).floor()}m', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFE8FF47)),
                  onTap: () {
                    // Navigate to the detail page, passing the full WorkoutLog object
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WorkoutDetailPage(workout: workout)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
