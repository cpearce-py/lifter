// features/workouts/ui/widgets/workout_live_stats.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/ble_provider.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

class WorkoutLiveStats extends StatelessWidget {
  final int secondsRemaining;

  const WorkoutLiveStats({
    super.key,
    required this.secondsRemaining,
  });

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CurrentWeight(),
          
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.1)),
          
          Column(
            children: [
              Text(
                _formatTime(secondsRemaining),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0, letterSpacing: -1.5),
              ),
              const Text('TIME LEFT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class CurrentWeight extends ConsumerWidget {
  const CurrentWeight({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightAsync = ref.watch(liveWeightStreamProvider);
    final currentWeight = weightAsync.value ?? 0.0;

    return Column(
      children: [
        Text(
          currentWeight.toStringAsFixed(1),
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0, letterSpacing: -1.5),
        ),
        const Text('KILOGRAMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.5)),
      ],
    );
  }
}
