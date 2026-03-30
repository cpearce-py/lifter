
import 'package:flutter/material.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

// features/workouts/ui/widgets/workout_top_bar.dart

class WorkoutTopBar extends StatelessWidget {
  final String phaseName;
  final VoidCallback onClose;
  final Widget? trailing; // <-- THE MAGIC NEW PARAMETER

  const WorkoutTopBar({
    super.key,
    required this.phaseName,
    required this.onClose,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Back Button
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: onClose,
          ),
          
          // 2. Phase Name
          Text(
            phaseName.toUpperCase(),
            style: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 2.0, 
              color: AppColors.repeaterAccent, // Note: You can also pass color in to make this dynamic!
            ),
          ),
          
          // 3. Dynamic Trailing Content (or an empty box if null to keep the title centered)
          trailing ?? const SizedBox(width: 48), 
        ],
      ),
    );
  }
}
