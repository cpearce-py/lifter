import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/core/models/workout_session.dart';
import 'package:lifter/core/ui/widgets/controls.dart';
import 'package:lifter/features/workouts/sessions/live_graph_page.dart';
import 'package:lifter/features/workouts/ui/config_pages/peak_load_config_page.dart';
import 'package:lifter/features/workouts/ui/config_pages/repeater_config_page.dart';

class WorkoutSelectionSheet extends ConsumerStatefulWidget {
  const WorkoutSelectionSheet({super.key});

  @override
  ConsumerState<WorkoutSelectionSheet> createState() =>
      _WorkoutSelectionSheetState();
}

class _WorkoutSelectionSheetState extends ConsumerState<WorkoutSelectionSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  List<WorkoutType> _getWorkouts(BuildContext context) => [

    WorkoutType(
      name: 'Live Graph',
      description: 'Mess with the live graph.',
      icon: Icons.timeline_rounded,
      accentColor: context.streakAccent,
      setupPageBuilder: (context) => const LiveGraphPage(),
    ),

    WorkoutType(
      name: 'Repeaters',
      description: 'Timed hang sets with rest intervals',
      icon: Icons.repeat_rounded,
      accentColor: context.repeaterAccent,
      setupPageBuilder: (context) => const RepeaterSetupPage(),
    ),

    WorkoutType(
      name: 'Peak Load',
      description: 'Measure your maximum single effort',
      icon: Icons.arrow_upward_rounded,
      accentColor: context.peakLoadAccent,
      setupPageBuilder: (context) =>
          const PeakLoadSetupPage(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  // 4. Clean up the controller
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openWorkout(BuildContext context, WorkoutType workout) {
    HapticFeedback.lightImpact();

    // Push using rootNavigator so it covers the bottom nav bar
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(CupertinoPageRoute(builder: workout.setupPageBuilder));
  }

  @override
  Widget build(BuildContext context) {
    final workouts = _getWorkouts(context);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return FadeSlide(
          animation: _controller,
          intervalStart: 0.1 + (index * 0.1),
          intervalEnd: 0.6 + (index * 0.1),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _WorkoutCard(
              workout: workout,
              onTap: () => _openWorkout(context, workout),
            ),
          ),
        );
      },
    );
  }
}

class _WorkoutCard extends StatefulWidget {
  const _WorkoutCard({required this.workout, required this.onTap});

  final WorkoutType workout;
  final VoidCallback onTap;

  @override
  State<_WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<_WorkoutCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _press, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workout;

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: w.accentColor.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: w.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(w.icon, color: w.accentColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.name,
                      style: context.body.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      w.description,
                      style: TextStyle(fontSize: 12, color: context.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: w.accentColor.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
