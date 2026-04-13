import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/database/database_service.dart';
import 'package:lifter/core/measurements/widgets/weight_input.dart';
import 'package:lifter/core/measurements/widgets/weight_text.dart';
import 'package:lifter/core/providers/history_provider.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/core/ui/widgets/app_card.dart';
import 'package:lifter/core/ui/widgets/controls.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import '../providers/user_settings_provider.dart';

Future<void> _confirmNukeDatabase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context, 
      // Forces me to actually tap a button instead of just tapping outside the box!
      barrierDismissible: false, 
      builder: (context) => AlertDialog(
        backgroundColor: context.background,
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text("Nuke Database?", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'This will permanently delete ALL workouts, sets, and reps from your device. This action cannot be undone.\n\nAre you absolutely sure?', 
          style: TextStyle(color: context.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent, // Deep red for danger
            ),
            child: const Text('Nuke Everything', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );

    // If they hit cancel or dismissed it, stop right here.
    if (confirmed != true) return;

    HapticFeedback.heavyImpact();
    DatabaseService.instance.wipeDatabase();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database wiped clean.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final notifier = ref.watch(userSettingsProvider.notifier);
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
            padding: const EdgeInsets.symmetric(horizontal: 4),
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

            const SizedBox(height: 32),
            Text(
              'DEVELOPER TOOLS',
              style: context.overline,
            ),
            const SizedBox(height: 8),
            AppCard(
              label: 'Database Management',
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.danger,
                        side: BorderSide(color: context.danger.withOpacity(0.5)),
                      ),
                      onPressed: () {
                        _confirmNukeDatabase(context);
                        // HapticFeedback.heavyImpact();
                        // DatabaseService.instance.wipeDatabase();
                        // // Optional: Show a quick snackbar
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(content: Text('Database Wiped! Restart app.')),
                        // );
                      },
                      child: const Text('Nuke Database'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.success,
                        side: BorderSide(color: context.success.withOpacity(0.5)),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref.read(workoutHistoryProvider.notifier).injectDummyData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dummy Data Injected!')),
                        );
                      },
                      child: const Text('Seed Dummy Data'),
                    ),
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
