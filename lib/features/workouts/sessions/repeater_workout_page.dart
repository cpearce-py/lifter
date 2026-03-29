
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/features/workouts/notes/save_page.dart';
import 'package:lifter/features/workouts/ui/generic_widgets.dart';
import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/engines/repeater_engine.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/repeater_state.dart';
import 'package:lifter/features/workouts/workout_routing.dart';


Event? primaryButtonEvent(Phase phase) => switch (phase) {
  Phase.idle => Event.start,
  Phase.paused => Event.resume,
  Phase.working => Event.pause,
  Phase.resting => Event.skip,
  Phase.setResting => Event.skip,
  _ => null,
};

class RepeaterWorkoutPage extends ConsumerWidget {
  const RepeaterWorkoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // deals with re-routing to savepage
    listenToWorkoutCompletion(
      context, 
      ref, 
      provider: repeaterEngineProvider, 
      getPhase: (state)  => state.phase, 
      getFinalLog: () => ref.read(repeaterEngineProvider.notifier).getFinalSummary()
    );

    final state = ref.watch(repeaterEngineProvider);
    final phase = state.phase;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Column(
        children: [
          GenericWorkoutHeader(title: phase.name),
          Expanded(
            child: GenericGraphArea(
              phase: phase,
              overlay: _RepeaterOverlay(state: state)
            )
          ),
          GenericWorkoutControls(
            phase: phase, 
            onReset: () => ref.read(repeaterEngineProvider.notifier).dispatch(UserEventAction(Event.reset)), 
            onPrimaryAction: () {
              final event = primaryButtonEvent(phase);
              if (event != null) {
                ref.read(repeaterEngineProvider.notifier).dispatch(UserEventAction(event));
                }
              })
        ],
      )
    );
  }
}

// ─── Rep Counter Overlay ──────────────────────────────────────────────────────
 
class _RepeaterOverlay extends ConsumerWidget {
  const _RepeaterOverlay({
    required this.state,
  });
 
  final RepeaterState state;
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = state.phaseProgress;
    final accentColor = accentColorForPhase(state.phase);
 
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Set indicator
          Column(
            children: [
              _SetLabel(accentColor: accentColor),
              const SizedBox(height: 6),
               
              // Rep dots
              _RepDots(accentColor: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          // Let's add the hand indicator right below the set tracker!
          Text(
            'HAND: ${state.currentHand.name.toUpperCase()}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          // Circular countdown
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withOpacity(0.07),
                  valueColor: AlwaysStoppedAnimation(accentColor),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.phase == Phase.idle || state.phase == Phase.done
                          ? '–'
                          : '${state.secondsRemaining}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RepDots extends ConsumerWidget {
  const _RepDots({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (reps, currentRep) = ref.watch(
      repeaterEngineProvider.select((s) => (s.reps, s.currentRep))
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(reps, (i) {
        final done   = i < currentRep - 1;
        final active = i == currentRep - 1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 10 : 7,
            height: active ? 10 : 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (done || active)
                  ? accentColor
                  : accentColor.withOpacity(0.15),
            ),
          ),
        );
      }),
    );
  }
}

class _SetLabel extends ConsumerWidget {
  const _SetLabel({
    required this.accentColor,
  });

  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (currentSet, sets) = ref.watch(
      repeaterEngineProvider.select((s) => (s.currentSet, s.sets))
    );
    return Text(
      'SET $currentSet/$sets',
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: accentColor.withOpacity(0.6),
      ),
    );
  }
}
