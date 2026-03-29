import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/history_provider.dart';
import 'package:lifter/features/history/ui/workout_detail_page.dart';
import 'package:lifter/features/history/ui/workout_theme_extension.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: historyAsync.when(
        // We only show the main loading spinner on the VERY FIRST load
        skipLoadingOnReload: true, 
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFE8FF47))),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
        data: (paginationState) {
          final workouts = paginationState.workouts;

          if (workouts.isEmpty) {
            return Center(
              child: Text(
                'No workouts yet.\n',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
              ),
            );
          }

          // If there are more pages, we add +1 to the list to make room for the button
          final itemCount = workouts.length + (paginationState.hasMore ? 1 : 0);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              
              // --- Render the "Load More" Button at the bottom ---
              if (index == workouts.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: historyAsync.isRefreshing 
                      // Show a tiny spinner inside the button area while the next 20 fetch
                      ? const CircularProgressIndicator(color: Color(0xFFE8FF47))
                      : OutlinedButton(
                          onPressed: () {
                            ref.read(workoutHistoryProvider.notifier).loadMore();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: const Text('Load Older Workouts', style: TextStyle(color: Colors.white)),
                        ),
                  ),
                );
              }

              // --- Render the Normal Workout Card ---
              final workout = workouts[index];
              final dateStr = workout.dateDone.toLocal().toString().split(' ')[0]; 

              final colour = workout.uiAccentColor;
              final icon = workout.uiIcon;
              
              return Card(
                color: Colors.white.withValues(alpha: 0.05),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: colour.withValues(alpha: 0.15),
                    child: Icon(icon, color: colour, size: 20),
                  ),

                  title: Text(
                  workout.uiTitle,
                    // getWorkoutName(workout.workoutTypeId),
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

                  trailing: Icon(Icons.chevron_right, color: colour),
                  onTap: () {
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
