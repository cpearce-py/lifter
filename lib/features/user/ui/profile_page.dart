import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/measurements/widgets/weight_input.dart';
import 'package:lifter/core/measurements/widgets/weight_text.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/core/ui/widgets/app_card.dart';
import 'package:lifter/core/ui/widgets/controls.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import '../providers/user_settings_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final notifier = ref.read(userSettingsProvider.notifier);
    final accent = context.repeaterAccent;

    return Scaffold(
      backgroundColor: context.background,
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 32,
                24,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROFILE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      color: accent.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Settings', 
                    style: context.h1,
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // --- Metric Toggle ---
                AppCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  label: 'Measurement Unit',
                  child: SegmentedControl(
                    choices: const ['Metric (kg)', 'Imperial (lbs)'],
                    selectedIndex: settings.useLbs ? 1 : 0,
                    accentColor: accent,
                    onChanged: (index) => notifier.toggleMetric(index == 1),
                  ),
                ),

                // --- Body Weight ---
                AppCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  label: 'Body Weight',
                  child: WeightInput(
                    weightKg: settings.bodyWeight,
                    accentColor: accent,
                    onChangedKg: (newKg) => notifier.updateWeight(newKg),
                  ),
                ),

                // --- Preferred Hand ---
                AppCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  label: 'Preferred Starting Hand',
                  child: SegmentedControl(
                    choices: Hand.values.map((h) => h.label).toList(),
                    selectedIndex: settings.preferredHand.index,
                    accentColor: accent,
                    onChanged: (index) =>
                        notifier.updateHand(Hand.values[index]),
                  ),
                ),

                // --- Max Pulls ---
                AppCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  label: 'Personal Bests (Max Pull)',
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Left Hand",
                            style: TextStyle(color: context.textPrimary),
                          ),
                          WeightText(
                            weightKg: settings.maxPullLeft,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Right Hand",
                            style: TextStyle(color: context.textPrimary),
                          ),
                          WeightText(
                            weightKg: settings.maxPullRight,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppCard(
                  label: "Light Mode",
                  child: SegmentedControl(
                    choices: const ["System", "Light", "Dark"],
                    selectedIndex: settings.themeMode.index,
                    accentColor: accent,
                    onChanged: (index) {
                      notifier.updateThemeMode(ThemeMode.values[index]);
                    },
                  ),
                ),
                const SizedBox(height: 100), // Bottom padding for nav bar
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
