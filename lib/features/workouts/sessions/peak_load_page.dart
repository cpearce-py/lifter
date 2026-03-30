import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/features/workouts/engines/peak_load_engine.dart';
import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/peak_load_state.dart';
import 'package:lifter/features/workouts/sessions/repeater_workout_page.dart';
import 'package:lifter/features/workouts/ui/generic_widgets.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_top_bar.dart';
import 'package:lifter/features/workouts/workout_routing.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

class PeakLoadSessionPage extends ConsumerWidget {
  const PeakLoadSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenToWorkoutCompletion(
      context,
      ref,
      provider: peakLoadEngineProvider,
      getPhase: (state) => state.phase,
      getFinalLog: () => ref.read(peakLoadEngineProvider.notifier).getFinalSummary(),
    );
    final state = ref.watch(peakLoadEngineProvider);
    final phase = state.phase;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
          WorkoutTopBar(
            phaseName: phase.name, 
            trailing: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ROUND ${state.repCount}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.peakLoadAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.currentHand.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.peakLoadAccent),
                      ),
                    ),
                  ],
                ),
              ),
            onClose: () => Navigator.of(context).pop(),
          ),

          StatInfoBar(timeProvider: peakLoadEngineProvider.select((s) => s.secondsRemaining)),

          Expanded(
            child: GenericGraphArea(
              phase: phase,
              overlay: 
              Text(
                'HAND: ${state.currentHand.name.toUpperCase()}',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),

          if (phase == Phase.resting)
            _PeakLoadRestControls(state: state)
          else
            GenericWorkoutControls(
              phase: phase,
              onReset: () => ref
                  .read(peakLoadEngineProvider.notifier)
                  .dispatch(UserEventAction(Event.reset)),
              onPrimaryAction: () {
                final event = primaryButtonEvent(phase);
                if (event != null) {
                  ref
                      .read(peakLoadEngineProvider.notifier)
                      .dispatch(UserEventAction(event));
                }
              },
            ),
          ],
      )),
    );
  }
}

class _PeakLoadRestControls extends ConsumerWidget {
  final PeakLoadState state;
  const _PeakLoadRestControls({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (!state.isLeftStopped)
            ElevatedButton(
              onPressed: () {
                ref
                    .read(peakLoadEngineProvider.notifier)
                    .dispatch(StopHandAction(Hand.left));
              },
              child: const Text('Stop Left'),
            ),
          if (!state.isRightStopped)
            ElevatedButton(
              onPressed: () {
                ref
                    .read(peakLoadEngineProvider.notifier)
                    .dispatch(StopHandAction(Hand.right));
              },
              child: const Text('Stop Right'),
            ),
          ElevatedButton(
            onPressed: () => ref
                .read(peakLoadEngineProvider.notifier)
                .dispatch(UserEventAction(Event.finish)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Finish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
