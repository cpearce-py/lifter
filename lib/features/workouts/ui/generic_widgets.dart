import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/graph_controller_provider.dart';
import 'package:lifter/features/workouts/ui/graph.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

// --- Helpers ---
({String label, Color color, IconData icon}) getPrimaryActionConfig(Phase phase, BuildContext context) {
  return switch (phase) {

    Phase.idle => (
      label: "Start",
      color: context.success,
      icon: Icons.play_arrow_rounded,
    ),

    Phase.starting => (
      label: "Get ready!",
      color: context.repeaterAccent,
      icon: Icons.timer_rounded,
    ),

    Phase.switching => (
      label: "Swap Hands",
      color: context.swapHandAccent,
      icon: Icons.swap_horiz_rounded, // The new swap icon!
    ),

    Phase.working => (
      label: "Pause",
      color: context.danger,
      icon: Icons.pause_rounded,
    ),

    Phase.paused => (
      label: "Resume",
      color: context.success,
      icon: Icons.play_arrow_rounded,
    ),

    Phase.resting || Phase.setResting => ( // You can even combine identical states!
      label: "Skip Rest",
      color: phase == Phase.resting ? context.streakAccent : context.setRestAccent,
      icon: Icons.skip_next_rounded,
    ),

    Phase.done => (
      label: "Finished!",
      color: context.success,
      icon: Icons.check_circle_outline_rounded,
    ),

    Phase.cancelled => (
      label: "Cancelled",
      color: context.buttonSecondary,
      icon: Icons.close_rounded,
    ),
  };
}

Color accentColorForPhase(Phase phase, BuildContext context) => switch (phase) {
  Phase.working => context.repeaterAccent,
  Phase.resting => context.streakAccent,
  Phase.setResting => context.setRestAccent,
  Phase.paused => context.danger,
  Phase.done => context.success,
  Phase.switching => context.swapHandAccent,
  _ => context.repeaterAccent,
};


class GenericGraphArea extends ConsumerWidget {
  final Phase phase;
  final Widget? overlay; // Specific overlay in topright of graph

  const GenericGraphArea({super.key, required this.phase, this.overlay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = accentColorForPhase(phase, context);

    final isGraphActive =
        phase != Phase.idle &&
        phase != Phase.done &&
        phase != Phase.cancelled &&
        phase != Phase.paused;

    final controller = ref.watch(graphControllerProvider);

    return Stack(
      children: [
        Positioned.fill(
          child: LiveGraph(
            controller: controller,
            accentColor: accentColor,
            showPeakLine: true,
            isActive: isGraphActive,
          ),
        ),
        if (overlay != null) Positioned(top: 12, right: 12, child: overlay!),
      ],
    );
  }
}

class GenericWorkoutControls extends StatelessWidget {
  final Phase phase;
  final VoidCallback onReset;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;

  const GenericWorkoutControls({
    super.key,
    required this.phase,
    required this.onReset,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final primaryConfig = getPrimaryActionConfig(phase, context);

    final showSecondary = phase == Phase.paused || 
                          phase == Phase.resting || 
                          phase == Phase.setResting;

    return Row(
      children: [
        // Reset Button
        GestureDetector(
          onTap: () {
            if (phase != Phase.idle) {
              onReset();
            }
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: context.buttonSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.textSubtle),
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: context.textMuted,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
    
        // Secondary button.
        if (showSecondary) ...[
          Expanded(
            child: _WorkoutButton(
              label: "Finish", 
              icon: Icons.exit_to_app, 
              backgroundColor: context.buttonSecondary, 
              textColor: context.danger, 
              onTap: onSecondaryAction
            ),
          ),
          const SizedBox(width: 12),
        ],
    
        // Start/Stop Button
        Expanded(
          child: _WorkoutButton(
            label: primaryConfig.label, 
            icon: primaryConfig.icon, 
            backgroundColor: primaryConfig.color, 
            textColor: context.textPrimaryInv, 
            onTap: onPrimaryAction
          ),
        ),
      ],
    );
  }
}

class _WorkoutButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _WorkoutButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: 22),
              const SizedBox(width: 6),
              // Make sure to pull the base style from your theme context properly
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
