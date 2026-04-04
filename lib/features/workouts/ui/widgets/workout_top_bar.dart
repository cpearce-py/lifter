
import 'package:flutter/material.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

class WorkoutTopBar extends StatelessWidget {
  final String phaseName;
  final VoidCallback onClose;
  final Widget? trailing;
  final Color accent;

  const WorkoutTopBar({
    super.key,
    required this.phaseName,
    required this.onClose,
    required this.accent,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          IconButton(
            icon: Icon(Icons.close_rounded, color: context.textPrimary),
            onPressed: onClose,
          ),
          
          Text(
            phaseName.toUpperCase(),
            style: context.h1.copyWith(
              fontSize: 18,
              color: accent,
            ),
          ),
          
          // Dynamic Trailing Content
          trailing ?? const SizedBox(width: 48), 
        ],
      ),
    );
  }
}
