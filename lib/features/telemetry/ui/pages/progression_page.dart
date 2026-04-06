import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifter/features/telemetry/ui/charts/max_pull.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/telemetry/ui/charts/workouts_per_month.dart';
import 'package:lifter/features/telemetry/ui/widgets/chart_card.dart';

class ProgressionPage extends ConsumerWidget {
  const ProgressionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Read from your real Riverpod data providers here!
    // For now, I'll mock the data so you can see it render:
    final mockPullData = [
      MaxPullPoint(date: DateTime.now(), leftMax: 20.5, rightMax: 21.0),
      MaxPullPoint(date: DateTime.now(), leftMax: 22.0, rightMax: 22.5),
      MaxPullPoint(
        date: DateTime.now(),
        leftMax: 24.5,
        rightMax: 23.0,
      ),
    ];

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        title: Text('Progression', style: context.h1.copyWith(fontSize: 24)),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            ChartCard(
              title: 'Consistency',
              subtitle: 'Workouts completed per month',
              child: WorkoutsProgressionChart(),
            ),

            ChartCard(
              title: 'Peak Load History',
              subtitle: 'Max weight pulled per hand over time',
              child: MaxPullProgressionChart(progressionData: mockPullData),
            ),

            // Add more ChartCards here in the future effortlessly!
          ],
        ),
      ),
    );
  }
}
