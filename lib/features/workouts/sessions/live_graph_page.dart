import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/ui/generic_widgets.dart';
import 'package:lifter/features/workouts/ui/graph.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_live_stats.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_top_bar.dart';


class LiveGraphPage extends ConsumerWidget {
  const LiveGraphPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    const double hPad = 15.0;
    const double sectionSpacing = 18.0;
    
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Column(
          children: [
            WorkoutTopBar(
              onClose: () => Navigator.of(context).pop(),
              title: Text(
                "Live Graph",
                style: context.h1.copyWith(
                  fontSize: 18,
                  color: context.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: sectionSpacing),
            CurrentWeight(),
            const SizedBox(height: sectionSpacing),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: hPad),
                child: LiveGraph(
                  controller: LiveGraphController(),
                  accentColor: context.streakAccent,
                  showPeakLine: true,
                ),
              ),
            ),
            const SizedBox(height: sectionSpacing),
          ],
        ),
      ),
    );
  }
}
