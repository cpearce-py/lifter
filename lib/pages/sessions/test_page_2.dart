import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/providers/workout_provider.dart';
import 'package:lifter/widgets/graph.dart';

class MyRepeaterPage extends ConsumerWidget {
  static const _accentColor    = Color(0xFFE8FF47);
  static const _restColor      = Color(0xFF47C8FF);
  static const _setRestColor   = Color(0xFFB47FFF);

  static const _accentForPhase = {
    Phase.working: _accentColor,
    Phase.resting: _restColor,
    Phase.setResting: _setRestColor,
  };

  const MyRepeaterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Column(
        children: [
          WorkoutHeader(),
          Expanded(child: GraphArea(accentColor: _accentColor,)),
          WorkoutControlsSection(accentColor: _accentColor),
        ],
      )
    );
  }
}

class GraphArea extends ConsumerWidget {
  const GraphArea({
    super.key,
    required Color accentColor,
  }) : _accentColor = accentColor;

  final Color _accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRecording = ref.watch(
      workoutNotifierProvider.select((s) => s.phase == Phase.working)
    );
    final controller = ref.watch(graphControllerProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Stack(
        children: [
          // Graph fills the space
          Positioned.fill(
            child: LiveGraph(
              controller: controller,
              accentColor: _accentColor,
              showPeakLine: true,
              isRecording: isRecording,
            ),
          ),
          // Overlay sits on top (top-right corner by default)
          // if (overlay != null)
          //   Positioned(
          //     top: 12,
          //     right: 12,
          //     child: overlay!,
          //   ),
        ],
      ),
    );
  }
}

class WorkoutControlsSection extends ConsumerWidget {
  const WorkoutControlsSection({
    super.key,
    required Color accentColor,
  }) : _accentColor = accentColor;

  final Color _accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutPhase = ref.watch(
      workoutNotifierProvider.select((s) => s.phase)
    );
    final notifier = ref.read(workoutNotifierProvider.notifier);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 24),
      child: Row(
        children: [
          // Reset
          GestureDetector(
            onTap: () {
              if (workoutPhase != Phase.idle) {
                HapticFeedback.lightImpact();
                notifier.reset();
                debugPrint("Reset statemachine");
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
          StartStopButton(accentColor: _accentColor),
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

    final notifier = ref.read(workoutNotifierProvider.notifier);

    final workoutPhase = ref.watch(
      workoutNotifierProvider.select((s) => s.phase)
    );

    final isRecording = workoutPhase == Phase.working;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          final event = primaryButtonEvent(workoutPhase);
          if (event != null){
          notifier.send(event);
          debugPrint("Sent event: $event");
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
      workoutNotifierProvider.select((s) => s.phase)
    );
    return Expanded(
      child: Text(
        workoutPhase.name,
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
