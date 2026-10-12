import 'package:flutter/material.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lifter/features/bluetooth/ble_manager.dart';

// ─── 1. Connect Bluetooth Button ──────────────────────────────────────────────

class ConnectBluetoothButton extends StatelessWidget {
  const ConnectBluetoothButton({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FlutterBluePlus.isScanning,
      initialData: FlutterBluePlus.isScanningNow,
      builder: (context, snapshot) {
        final isScanning = snapshot.data ?? false;

        final color = isScanning ? context.danger : context.streakAccent;
        final label = isScanning ? 'Stop Reading' : 'Start Reading';
        final icon = isScanning ? Icons.sensors_off_rounded : Icons.sensors_rounded;

        return GestureDetector(
          onTap: () {
            if (isScanning) {
              BleManager.instance.stopListening();
            } else {
              BleManager.instance.startListening();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
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
      },
    );
  }
}

// ─── 2. BLE Status Dot ────────────────────────────────────────────────────────

class BleStatusDot extends StatelessWidget {
  const BleStatusDot({
    super.key,
    this.size = 10.0,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FlutterBluePlus.isScanning,
      initialData: FlutterBluePlus.isScanningNow,
      builder: (context, snapshot) {
        final isScanning = snapshot.data ?? false;

        final color = isScanning ? context.streakAccent : context.textSubtle;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: isScanning
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
        );
      },
    );
  }
}
