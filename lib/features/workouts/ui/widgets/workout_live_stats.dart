import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/measurements/unit_converter.dart';
import 'package:lifter/core/providers/ble_provider.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';

class WorkoutLiveStats extends StatelessWidget {
  final int secondsRemaining;

  const WorkoutLiveStats({super.key, required this.secondsRemaining});

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CurrentWeight(),

          Container(width: 1, height: 50, color: context.cardBorder),

          Column(
            children: [
              Text(
                _formatTime(secondsRemaining),
                style: context.hero,
              ),
              Text(
                'TIME LEFT',
                style: context.overline.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CurrentWeight extends ConsumerWidget {
  const CurrentWeight({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightAsync = ref.watch(liveWeightStreamProvider);
    final rawWeightKg = weightAsync.value ?? 0.0;
    
    final useLbs = ref.watch(userSettingsProvider.select((s) => s.useLbs));
    
    final displayWeight = useLbs ? kgToLbs(rawWeightKg) : rawWeightKg;
    final labelText = useLbs ? 'POUNDS' : 'KILOGRAMS';

    return Column(
      children: [
        Text(
          displayWeight.toStringAsFixed(1),
          style: context.hero,
        ),
        Text(
          labelText,
          style: context.overline.copyWith(
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
