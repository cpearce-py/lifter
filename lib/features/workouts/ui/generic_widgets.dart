import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/graph_controller_provider.dart';
import 'package:lifter/features/workouts/ui/graph.dart';
import 'package:lifter/features/workouts/models/base_models.dart';

// --- Helpers ---
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

Color accentColorForPhase(Phase phase) => switch (phase) {
  Phase.working    => const Color(0xFFE8FF47),
  Phase.resting    => const Color(0xFF47C8FF),
  Phase.setResting => const Color(0xFFB47FFF),
  Phase.paused     => const Color(0xFFFF7F7F),
  Phase.done       => const Color(0xFF81FF7F),
  _                => const Color(0xFFE8FF47),
};

class GenericWorkoutHeader extends StatelessWidget {
  final String title;
  
  const GenericWorkoutHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios_rounded, size: 20, color: Colors.white.withOpacity(0.6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: Color(0xFFF0F0F0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GenericGraphArea extends ConsumerWidget {
  final Phase phase;
  final Widget? overlay; // Specific overlay in topright of graph

  const GenericGraphArea({super.key, required this.phase, this.overlay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = accentColorForPhase(phase);
    final isGraphActive = phase != Phase.idle && 
                          phase != Phase.done && 
                          phase != Phase.cancelled &&
                          phase != Phase.paused;
    
    final controller = ref.watch(graphControllerProvider); 

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Stack(
        children: [
          Positioned.fill(
            child: LiveGraph(
              controller: controller,
              accentColor: accentColor,
              showPeakLine: true,
              isActive: isGraphActive,
            ),
          ),
          if (overlay != null)
            Positioned(
              top: 12,
              right: 12,
              child: overlay!,
            ),
        ],
      ),
    );
  }
}

class GenericWorkoutControls extends StatelessWidget {
  final Phase phase;
  final VoidCallback onReset;
  final VoidCallback onPrimaryAction;

  const GenericWorkoutControls({
    super.key,
    required this.phase,
    required this.onReset,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = accentColorForPhase(phase);
    final isRecording = phase == Phase.working;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 24),
      child: Row(
        children: [
          // Reset Button
          GestureDetector(
            onTap: () {
              if (phase != Phase.idle) {
                HapticFeedback.lightImpact();
                onReset();
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
              child: Icon(Icons.refresh_rounded, color: Colors.white.withOpacity(0.4), size: 22),
            ),
          ),
          const SizedBox(width: 12),
          
          // Start/Stop Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onPrimaryAction();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 52,
                decoration: BoxDecoration(
                  color: isRecording ? const Color(0xFFFF6B6B) : accentColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (isRecording ? const Color(0xFFFF6B6B) : accentColor).withOpacity(0.25),
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
                        isRecording ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        color: const Color(0xFF0A0A0F),
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        getPrimaryLabelForPhase(phase),
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
          ),
        ],
      ),
    );
  }
}
