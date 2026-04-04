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
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.cardBorder),
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: 4,
      minLines: 2,
      style: context.body,
      cursorColor: context.textPrimary,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: context.body.copyWith(
          color: context.textMuted.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: context.inputBackground,
        border: baseBorder,
        enabledBorder: baseBorder,
        focusedBorder: baseBorder,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
