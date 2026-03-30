// features/workouts/ui/widgets/workout_notes_field.dart
import 'package:flutter/material.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

class WorkoutNotesField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const WorkoutNotesField({
    super.key,
    required this.controller,
    this.hintText = 'How did this session feel?',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: 4,
      minLines: 2,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: AppColors.surfaceHighlight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
