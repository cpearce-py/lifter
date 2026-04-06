import 'package:flutter/material.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBackground, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, 
        mainAxisSize: MainAxisSize.min, 
        children: [
          Text(
            title,
            style: context.h1.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: context.body.copyWith(color: context.textMuted),
          ),
          const SizedBox(height: 32),
          child, 
        ],
      ),
    );
  }
}
