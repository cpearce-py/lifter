import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/measurements/unit_converter.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';

class WeightText extends ConsumerWidget {
  /// The raw weight stored in the database (Always in KG)
  final double weightKg;
  
  /// Optional prefix, e.g., 'L: ' or 'Target: '
  final String prefix;
  
  /// Text style to apply to the entire string
  final TextStyle? style;

  const WeightText({
    super.key,
    required this.weightKg,
    this.prefix = '',
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useLbs = ref.watch(userSettingsProvider.select((s) => s.useLbs));

    final displayWeight = useLbs ? kgToLbs(weightKg) : weightKg;
    final unitLabel = useLbs ? 'lbs' : 'kg';
    
    // Keeping a strict 1 decimal place makes lists of data align nicely
    final formattedWeight = displayWeight.toStringAsFixed(1);

    return Text(
      '$prefix$formattedWeight$unitLabel',
      style: style,
    );
  }
}
