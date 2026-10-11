import 'package:flutter/material.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/core/ui/widgets/controls.dart';
import 'package:lifter/features/workouts/models/grip.dart';

/// Picks the grip and edge for a workout or block. Both are optional, so
/// the first choice in each dropdown means "not set".
class GripSetupCard extends StatelessWidget {
  const GripSetupCard({
    super.key,
    required this.grip,
    required this.accentColor,
    required this.onChanged,
  });

  final GripSetup grip;
  final Color accentColor;
  final ValueChanged<GripSetup> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grip & Edge', style: context.cardTitle),
          const SizedBox(height: 4),
          Text(
            'Tracked in History so you can compare progress',
            style: TextStyle(fontSize: 12, color: context.textMuted),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grip', style: context.body),
              DropdownControl(
                choices: ['Not set', ...GripType.values.map((g) => g.label)],
                selectedIndex: grip.grip == null ? 0 : grip.grip!.index + 1,
                accentColor: accentColor,
                onChanged: (i) => onChanged(
                  grip.withGrip(i == 0 ? null : GripType.values[i - 1]),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: context.cardBorder, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Edge', style: context.body),
              DropdownControl(
                choices: ['Not set', ...edgeSizesMm.map((mm) => '$mm mm')],
                selectedIndex: grip.edgeMm == null
                    ? 0
                    : edgeSizesMm.indexOf(grip.edgeMm!) + 1,
                accentColor: accentColor,
                onChanged: (i) => onChanged(
                  grip.withEdge(i == 0 ? null : edgeSizesMm[i - 1]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
