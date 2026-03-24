import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/scale_provider.dart';

class ConnectBluetoothButton extends ConsumerWidget {
  const ConnectBluetoothButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the hardware scanner state
    final isScanningAsync = ref.watch(isBluetoothScanningProvider);
    final isScanning = isScanningAsync.value ?? false;

    // Tweak the text to reflect the advertisement-only nature of your device
    final color = isScanning ? const Color(0xFFFF6B6B) : const Color(0xFF47C8FF);
    final label = isScanning ? 'Stop Reading' : 'Start Reading';
    final icon = isScanning ? Icons.sensors_off_rounded : Icons.sensors_rounded;

    return GestureDetector(
      onTap: () {
        if (isScanning) {
          ref.read(bleServiceProvider).stopListening();
        } else {
          ref.read(bleServiceProvider).startListening();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BleStatusDot extends ConsumerWidget {
  const BleStatusDot({
    super.key,
    this.size = 10.0,
  });

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the exact same hardware scanner state
    final isScanningAsync = ref.watch(isBluetoothScanningProvider);
    final isScanning = isScanningAsync.value ?? false;

    // Use a bright green/cyan for active, and a dim gray for inactive
    final color = isScanning ? const Color(0xFF47C8FF) : Colors.white.withOpacity(0.15);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: isScanning
            ? [
                // Add a soft glow when actively reading
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
    );
  }
}
