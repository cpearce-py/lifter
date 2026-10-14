import 'package:flutter/material.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

/// A yes/no dialog in the app's theme. Returns true only if [confirmLabel]
/// was tapped; cancelling or dismissing it returns false.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = true,
  bool barrierDismissible = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AlertDialog(
      backgroundColor: context.cardBackground,
      title: Text(title, style: context.body),
      content: Text(message, style: TextStyle(color: context.textMuted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel, style: TextStyle(color: context.textPrimary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: destructive ? context.danger : context.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
