import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/measurements/widgets/weight_input.dart';
import 'package:lifter/core/ui/widgets/app_card.dart';
import 'package:lifter/core/ui/widgets/controls.dart';
import 'package:lifter/features/workouts/engines/peak_load_engine.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/providers/peak_load_config_provider.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/workouts/sessions/peak_load_page.dart';

class PeakLoadSetupPage extends ConsumerWidget {
  const PeakLoadSetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(peakLoadSetupProvider);
    final notifier = ref.read(peakLoadSetupProvider.notifier);

    final accentColor = context.peakLoadAccent;

    return Scaffold(
      backgroundColor: context.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 16,
                24,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 14,
                          color: accentColor.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Workouts',
                          style: context.cardTitle.copyWith(
                            fontSize: 13,
                            color: accentColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text("PEAK LOAD", style: context.h1.copyWith(fontSize: 28)),
                  const SizedBox(height: 2),
                  Text(
                    "Measure your maximum single effort",
                    style: TextStyle(fontSize: 13, color: context.textMuted),
                  ),
                ],
              ),
            ),
          ),

          // 2. Form Controls
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                AppCard(
                  label: "Body weight",
                  child: WeightInput(
                    weightKg: config.bodyWeight,
                    accentColor: accentColor,
                    onChangedKg: notifier.updateBodyWeight,
                  ),
                ),
                const SizedBox(height: 10),

                AppCard(
                  label: "Rest time",
                  child: StepperControl(
                    value: config.restSeconds.toDouble(),
                    min: 120,
                    max: 300,
                    step: 30,
                    unit: "s",
                    accentColor: accentColor,
                    onChanged: notifier.updateRestSeconds,
                  ),
                ),
                const SizedBox(height: 10),

                AppCard(
                  label: "Starting hand",
                  child: SegmentedControl(
                    choices: Hand.values.map((h) => h.label).toList(),
                    selectedIndex: config.startingHand.index,
                    accentColor: accentColor,
                    onChanged: notifier.updateStartingHand,
                  ),
                ),
              ]),
            ),
          ),

          // 3. Start Button
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                24,
                16,
                MediaQuery.of(context).padding.bottom + 40,
              ),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();

                  final activeState = notifier.buildActiveState();

                  Navigator.of(context, rootNavigator: true).push(
                    CupertinoPageRoute(
                      builder: (_) => ProviderScope(
                        overrides: [
                          peakLoadConfigProvider.overrideWithValue(activeState),
                        ],
                        child: const PeakLoadSessionPage(),
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Start Peak Load',
                      style: context.cardTitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.background,
                      ),
                    ),
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
