import 'package:flutter/material.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/ui/workout_detail_page.dart';
import 'package:lifter/features/history/ui/workout_theme_extension.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

class WorkoutCard extends StatelessWidget {
  final WorkoutLog workout;

  const WorkoutCard({super.key, required this.workout});

  String _getDaysAgo(DateTime date) {
    final now = DateTime.now();
    
    // Strip the time to create pure "Midnight" calendar days
    final today = DateTime(now.year, now.month, now.day);
    final workoutDay = DateTime(date.year, date.month, date.day);
    
    final difference = today.difference(workoutDay).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return '${difference}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = workout.uiAccentColor(context);
    final title = workout.uiTitle;
    final icon = workout.uiIcon;
    final durationStr = '${(workout.duration / 60).floor()} min';
    final daysAgoStr = _getDaysAgo(workout.dateDone);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WorkoutDetailPage(workout: workout)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cardBorder, width: 1),
        ),
        child: Row(
          children: [
            // Icon Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color.withOpacity(0.7), size: 20),
            ),
            const SizedBox(width: 14),
            
            // Text Block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.cardTitle.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    durationStr,
                    style: context.body.copyWith(
                      fontSize: 12,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            
            // Days Ago
            Text(
              daysAgoStr,
              style: context.body.copyWith(
                fontSize: 11,
                color: context.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
