import 'package:flutter/material.dart';
import 'package:lifter/core/ui/themes/app_theme.dart'; // Import your theme!

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.label,
    required this.child,
    this.margin,
  });

  final String label;
  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
