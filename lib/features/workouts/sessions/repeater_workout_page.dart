
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/graph_controller_provider.dart';
import 'package:lifter/features/workouts/graph.dart';
import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/engines/repeater_engine.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/repeater_state.dart';

String getPrimaryLabelForPhase(Phase phase) => switch (phase) {
  Phase.idle => "Start",
  Phase.starting => "Get ready!",
  Phase.switching => "Swap Hands",
  Phase.paused => "Resume",
  Phase.cancelled => "Cancelled", 
  Phase.working => "Pause",
  Phase.done => "Finished!",
  Phase.resting => "Skip Rest",
  Phase.setResting => "Skip Rest"
};

Event? primaryButtonEvent(Phase phase) => switch (phase) {
  Phase.idle => Event.start,
  Phase.paused => Event.resume,
  Phase.working => Event.pause,
  Phase.resting => Event.skip,
  Phase.setResting => Event.skip,
  _ => null,
};

Color accentColorForPhase(Phase phase) => switch (phase) {
  Phase.working    => const Color(0xFFE8FF47),
  Phase.resting    => const Color(0xFF47C8FF),
  Phase.setResting => const Color(0xFFB47FFF),
  Phase.paused     => const Color(0xFFFF7F7F),
  Phase.done       => const Color(0xFF81FF7F),
  _                => const Color(0xFFE8FF47),
};


class RepeaterWorkoutPage extends ConsumerWidget {
  const RepeaterWorkoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    ref.listen<RepeaterState>(
      repeaterEngineProvider, 
      (previous, next) {
        if (previous?.phase != Phase.done && next.phase == Phase.done) {
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const Text("Good job")),
              );
            }
          });
        }
      });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Column(
        children: const [
          WorkoutHeader(),
          Expanded(child: GraphArea()),
          WorkoutControlsSection(),
        ],
      )
    );
  }
}

class GraphArea extends ConsumerWidget {
  const GraphArea({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(
      repeaterEngineProvider.select((s) => s.phase)
    );
    final accentColor = accentColorForPhase(phase);
    final isGraphActive = phase != Phase.idle && 
                          phase != Phase.done &&
                          phase != Phase.cancelled;
    final controller = ref.watch(graphControllerProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Stack(
        children: [
          // Graph fills the space
          Positioned.fill(
            child: LiveGraph(
              controller: controller,
              accentColor: accentColor,
              showPeakLine: true,
              isActive: isGraphActive,
            ),
          ),
          // Overlay sits on top (top-right corner by default)
          Positioned(
            top: 12,
            right: 12,
            child: _RepCounterOverlay(accentColor: accentColor),
          ),
        ],
      ),
    );
  }
}

class WorkoutControlsSection extends ConsumerWidget {
  const WorkoutControlsSection({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(
      repeaterEngineProvider.select((s) => s.phase)
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 24),
      child: Row(
        children: [
          // Reset
          GestureDetector(
            onTap: () {
              if (phase != Phase.idle) {
                HapticFeedback.lightImpact();
                ref.read(repeaterEngineProvider.notifier).dispatch(UserEventAction(Event.reset));
              }
           },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(Icons.refresh_rounded,
                  color: Colors.white.withOpacity(0.4), size: 22),
            ),
          ),
          const SizedBox(width: 12),
    
          // Start / Stop
          StartStopButton(accentColor: accentColorForPhase(phase)),
        ],
      ),
    );
  }
}

class WorkoutHeader extends StatelessWidget {
  const WorkoutHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 20, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios_rounded,
                size: 20, color: Colors.white.withOpacity(0.6)),
          ),
          const SizedBox(width: 12),
          HeaderLabel(),
        ],
      ),
    );
  }
}

class StartStopButton extends ConsumerWidget {
  const StartStopButton({
    super.key,
    required Color accentColor,
  }) : _accentColor = accentColor;

  final Color _accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final workoutPhase = ref.watch(
      repeaterEngineProvider.select((s) => s.phase)
    );

    final isRecording = workoutPhase == Phase.working;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          final event = primaryButtonEvent(workoutPhase);
          debugPrint("Primary button event: $event");
          if (event != null){
          ref.read(repeaterEngineProvider.notifier).dispatch(UserEventAction(event));
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 52,
          decoration: BoxDecoration(
            color: isRecording
                ? const Color(0xFFFF6B6B)
                : _accentColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (isRecording
                        ? const Color(0xFFFF6B6B)
                        : _accentColor)
                    .withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isRecording
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  color: const Color(0xFF0A0A0F),
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  getPrimaryLabelForPhase(workoutPhase),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A0A0F),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeaderLabel extends ConsumerWidget {
  const HeaderLabel({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutPhase = ref.watch(
      repeaterEngineProvider.select((s) => s.phase)
    );
    return Expanded(
      child: Text(
        workoutPhase.name.toUpperCase(),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: Color(0xFFF0F0F0),
        ),
      ),
    );
  }
}


// ─── Rep Counter Overlay ──────────────────────────────────────────────────────
 
class _RepCounterOverlay extends ConsumerWidget {
  const _RepCounterOverlay({
    required this.accentColor,
  });
 
  final Color accentColor;
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(repeaterEngineProvider);
    final progress = workoutState.phaseProgress;
 
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
                      workoutState.phase == Phase.idle || workoutState.phase == Phase.done
                          ? '–'
                          : '${workoutState.secondsRemaining}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        height: 1,
                      ),
                    ),
                    // Text(
                    //   workoutState.phase.name,
                    //   style: TextStyle(
                    //     fontSize: 7,
                    //     fontWeight: FontWeight.w700,
                    //     letterSpacing: 0.8,
                    //     color: accentColor.withOpacity(0.6),
                    //   ),
                    // ),
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
