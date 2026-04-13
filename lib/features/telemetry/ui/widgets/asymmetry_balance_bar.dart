import 'package:flutter/material.dart';
import 'package:lifter/features/telemetry/models.dart';

class AsymmetryBalanceBar extends StatelessWidget {
  final WorkoutStats stats;

  const AsymmetryBalanceBar({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final leftColor = Colors.blueAccent.shade100; 
    final rightColor = Colors.orangeAccent.shade100;
    
    final leftPct = (stats.balanceLeftPct * 100).toStringAsFixed(1);
    final rightPct = (stats.balanceRightPct * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'L/R Balance', 
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // The visual bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 24,
            child: Row(
              children: [
                Expanded(
                  flex: (stats.balanceLeftPct * 1000).toInt(),
                  child: Container(color: leftColor),
                ),
                Expanded(
                  flex: (stats.balanceRightPct * 1000).toInt(),
                  child: Container(color: rightColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // The text readouts
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Left: $leftPct%', style: TextStyle(color: leftColor, fontWeight: FontWeight.bold)),
            Text('Right: $rightPct%', style: TextStyle(color: rightColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
