import 'package:flutter/material.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/history_provider.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_card.dart';

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
        loading: () => Center(child: CircularProgressIndicator(color: context.repeaterAccent)),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: context.danger))),
        data: (paginationState) {
          final workouts = paginationState.workouts;

          if (workouts.isEmpty) {
            return Center(
              child: Text(
                'No workouts yet.\n',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textMuted, fontSize: 16),
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
                      ? CircularProgressIndicator(color: context.repeaterAccent)
                      : OutlinedButton(
                          onPressed: () {
                            ref.read(workoutHistoryProvider.notifier).loadMore();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.cardBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: Text('Load Older Workouts', style: TextStyle(color: context.textPrimary)),
                        ),
                  ),
                );
              }

              // --- Render the Normal Workout Card ---
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 6), 
                child: WorkoutCard(workout: workouts[index]),
              );
            },
          );
        },
      ),
    );
  }
}

