import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/features/workouts/engines/peak_load_engine.dart';
import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/peak_load_state.dart';
import 'package:lifter/features/workouts/sessions/repeater_workout_page.dart';
import 'package:lifter/features/workouts/ui/generic_widgets.dart';

class PeakLoadSessionPage extends ConsumerWidget {
  const PeakLoadSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(peakLoadEngineProvider);
    final phase = state.phase;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Column(
        children: [
          GenericWorkoutHeader(title: phase.name),

          Expanded(
            child: GenericGraphArea(
              phase: phase,
              overlay: _PeakLoadOverlay(
                state: state,
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
      ),
    );
  }
}

class _PeakLoadOverlay extends StatelessWidget {
  final PeakLoadState state;
  const _PeakLoadOverlay({required this.state});

  @override
  Widget build(BuildContext context) {
    final accentColor = accentColorForPhase(state.phase);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          // 1. The Circular Timer
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: state.phaseProgress,
                  strokeWidth: 3,
                  backgroundColor: Colors.white.withOpacity(0.07),
                  valueColor: AlwaysStoppedAnimation(accentColor),
                ),
                Text(
                  state.phase == Phase.idle || state.phase == Phase.done
                      ? '–'
                      : '${state.secondsRemaining}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TARGET: ${state.currentTarget.toStringAsFixed(1)} kg',
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'HAND: ${state.currentHand.name.toUpperCase()}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                'REP MAX: ${state.currentRepMax.toStringAsFixed(1)} kg',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
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
