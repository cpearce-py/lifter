import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/ble_provider.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/bluetooth/ble_manager.dart';

/// Says why no weight is coming in: Bluetooth off, no permission, or no
/// scale found yet. Takes no space while readings arrive.
class ScaleStatusBanner extends ConsumerWidget {
  const ScaleStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(scaleStatusProvider).value ?? ScaleStatus.idle;

    final (IconData, String, Color)? content = switch (status) {
      ScaleStatus.bluetoothOff => (
          Icons.bluetooth_disabled_rounded,
          'Turn on Bluetooth to read the scale',
          context.danger,
        ),
      ScaleStatus.unauthorized => (
          Icons.lock_outline_rounded,
          'Allow Bluetooth for Lifter in Settings',
          context.danger,
        ),
      ScaleStatus.unavailable => (
          Icons.bluetooth_disabled_rounded,
          'This device has no Bluetooth',
          context.danger,
        ),
      ScaleStatus.searching => (
          Icons.bluetooth_searching_rounded,
          'Looking for your scale…',
          context.textMuted,
        ),
      ScaleStatus.idle || ScaleStatus.receiving => null,
    };

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: content == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: content.$3.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(content.$1, size: 14, color: content.$3),
                    const SizedBox(width: 6),
                    Text(
                      content.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: content.$3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
