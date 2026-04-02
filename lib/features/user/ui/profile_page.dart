import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/measurements/widgets/weight_input.dart';
import 'package:lifter/core/measurements/widgets/weight_text.dart';
import 'package:lifter/core/ui/widgets/controls.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import '../providers/user_settings_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final notifier = ref.read(userSettingsProvider.notifier);
    const accent = Color(0xFFE8FF47);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
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
                  const Text(
                    'Your Data',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1.1,
                      color: Color(0xFFF0F0F0),
                    ),
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
                _SettingsCard(
                  label: 'Measurement Unit',
                  child: SegmentedControl(
                    choices: const ['Metric (kg)', 'Imperial (lbs)'],
                    selectedIndex: settings.useLbs ? 1 : 0,
                    accentColor: accent,
                    onChanged: (index) => notifier.toggleMetric(index == 1),
                  ),
                ),

                // --- Body Weight ---
                _SettingsCard(
                  label: 'Body Weight',
                  child: WeightInput(
                    weightKg: settings.bodyWeight,
                    accentColor: accent,
                    onChangedKg: (newKg) => notifier.updateWeight(newKg),
                  ),
                ),

                // --- Preferred Hand ---
                _SettingsCard(
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
                _SettingsCard(
                  label: 'Personal Bests (Max Pull)',
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Left Hand",
                            style: TextStyle(color: Colors.white70),
                          ),
                          WeightText(
                            weightKg: settings.maxPullLeft,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Right Hand",
                            style: TextStyle(color: Colors.white70),
                          ),
                          WeightText(
                            weightKg: settings.maxPullRight,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E2A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF0F0F0),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
