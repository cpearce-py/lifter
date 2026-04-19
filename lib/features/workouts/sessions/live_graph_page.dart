import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/bluetooth/ble_manager.dart';
import 'package:lifter/features/workouts/ui/graph.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_live_stats.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_top_bar.dart';


class LiveGraphPage extends ConsumerStatefulWidget {
  const LiveGraphPage({super.key});

  @override
  ConsumerState<LiveGraphPage> createState() => _LiveGraphPageState();
}

class _LiveGraphPageState extends ConsumerState<LiveGraphPage> {
  late final LiveGraphController _controller;
  StreamSubscription? _bleSub;

  @override
  void initState() {
    super.initState();
    
    // 1. Initialize the controller once
    _controller = LiveGraphController();

    // 2. Tell the hardware manager to start broadcasting (if needed)
    BleManager.instance.startListening();

    // 3. Pipe the live Bluetooth data directly into the graph controller
    _bleSub = BleManager.instance.weightStream.listen((reading) {
      _controller.addSample(reading.weightKg);
    });
  }

  @override
  void dispose() {
    // Always clean up streams and controllers to prevent memory leaks!
    _bleSub?.cancel();
    BleManager.instance.stopListening();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            const CurrentWeight(),
            const SizedBox(height: sectionSpacing),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: hPad),
                child: LiveGraph(
                  controller: _controller, // Pass the persistent state controller
                  accentColor: context.streakAccent,
                  showPeakLine: true,
                  isActive: true, // 4. This wakes up the Ticker and Stopwatch!
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
