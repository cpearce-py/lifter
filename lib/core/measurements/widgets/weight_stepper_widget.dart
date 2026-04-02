// core/ui/widgets/smart_weight_stepper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/ui/widgets/controls.dart';
import 'package:lifter/core/measurements/unit_converter.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';

class WeightStepper extends ConsumerWidget {
  /// The raw weight stored in the database (Always in KG)
  final double weightKg;
  
  /// Callback that returns the newly selected weight (Always in KG)
  final ValueChanged<double> onChangedKg;
  
  final Color accentColor;
  
  final double minKg;
  final double maxKg;

  const WeightStepper({
    super.key,
    required this.weightKg,
    required this.onChangedKg,
    required this.accentColor,
    this.minKg = 20.0,
    this.maxKg = 200.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Check the user's global preference
    final useLbs = ref.watch(userSettingsProvider.select((s) => s.useLbs));

    // 2. Calculate the UI values based on the preference
    final double displayValue = useLbs ? kgToLbs(weightKg) : weightKg;
    final double displayMin = useLbs ? kgToLbs(minKg) : minKg;
    final double displayMax = useLbs ? kgToLbs(maxKg) : maxKg;
    
    // In KG, a step of 1.0 makes sense. In LBS, 1.0 or 2.0 makes more sense.
    // We'll use 1.0 for both to keep it granular, but this can be adjusted!
    final double displayStep = 1.0; 
    final String displayUnit = useLbs ? 'lbs' : 'kg';

    return StepperControl(
      value: displayValue,
      min: displayMin,
      max: displayMax,
      step: displayStep,
      unit: displayUnit,
      accentColor: accentColor,
      onChanged: (newDisplayValue) {
        // 3. Convert the UI value back to KG before telling the rest of the app!
        final newKgValue = useLbs 
            ? lbsToKg(newDisplayValue) 
            : newDisplayValue;
            
        onChangedKg(newKgValue);
      },
    );
  }
}
