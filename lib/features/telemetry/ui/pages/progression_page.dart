import 'package:flutter/material.dart';

import 'package:lifter/features/telemetry/ui/charts/max_pull.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/telemetry/ui/charts/workouts_per_month.dart';
import 'package:lifter/features/telemetry/ui/widgets/chart_card.dart';

class ProgressionPage extends StatelessWidget {
  const ProgressionPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        title: Text('Progression', style: context.h1.copyWith(fontSize: 24)),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(4),
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
              child: MaxPullProgressionChart(),
            ),

            // Add more ChartCards here in the future effortlessly!
          ],
        ),
      ),
    );
  }
}
