import 'package:flutter/material.dart';
import 'package:lifter/features/telemetry/models.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

class AsymmetryBalanceBar extends StatelessWidget {
  final WorkoutStats stats;

  const AsymmetryBalanceBar({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final leftColor = context.leftHandAccent; 
    final rightColor = context.rightHandAccent;
    
    final leftPct = (stats.balanceLeftPct * 100).toStringAsFixed(1);
    final rightPct = (stats.balanceRightPct * 100).toStringAsFixed(1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 28,
        child: Row(
          children: [
            if (stats.balanceLeftPct > 0)
              Expanded(
                flex: (stats.balanceLeftPct * 1000).toInt(),
                child: Container(
                  color: leftColor,
                  alignment: Alignment.center,
                  child: Text(
                    'L: $leftPct%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip, // Prevents errors if the bar gets too tiny
                  ),
                ),
              ),
            if (stats.balanceRightPct > 0)
              Expanded(
                flex: (stats.balanceRightPct * 1000).toInt(),
                child: Container(
                  color: rightColor,
                  alignment: Alignment.center,
                  child: Text(
                    'R: $rightPct%',
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
