import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum WeightUnit { kg, lb, jin, unknown }

class WeightReading {
  final double weightKg;  // weight in kg (divide raw by 100)
  final bool isStable;
  final WeightUnit unit;

  WeightReading({
    required this.weightKg,
    required this.isStable,
    required this.unit,
  });
}

class BleManager {
  // ─── 1. The Singleton Boilerplate ────────────────────────────────────────────
  static final BleManager instance = BleManager._internal();
  
  // Private constructor prevents anyone else from instantiating this class
  BleManager._internal();

  // From manufacturer source: ManufacturerId = 256
  static const int _manufacturerId = 256;
  // Offsets within manufacturer-specific data
  static const int _weightOffset = 10;
  static const int _statusOffset = 14;

  final _weightController = StreamController<WeightReading>.broadcast();
  Stream<WeightReading> get weightStream => _weightController.stream;

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  Future<void> startListening() async {
    if (_scanSubscription != null) return;

    final state = await FlutterBluePlus.adapterState
      .where((s) => 
        s == BluetoothAdapterState.on ||
        s == BluetoothAdapterState.unauthorized ||
        s == BluetoothAdapterState.unavailable)
      .first;

    if (state != BluetoothAdapterState.on) {
      debugPrint('[BleManager] Bluetooth unavailable');
      return;
    }

    await FlutterBluePlus.startScan(
      continuousUpdates: true,
      removeIfGone: const Duration(seconds: 5),
    );

    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        _processResult(result);
      }
    });
  }

  void stopListening() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  void _processResult(ScanResult result) {
    final mfrData = result.advertisementData.manufacturerData[_manufacturerId];
    if (mfrData == null || mfrData.length <= _statusOffset) return;

    final reading = _decode(mfrData);
    if (reading != null) {
      _weightController.add(reading);
    }
  }

  WeightReading? _decode(List<int> bytes) {
    if (bytes.length < _statusOffset + 1) return null;

    // Weight: 16-bit big-endian at offset 10, unit is 0.01 kg
    final rawWeight =
        ((bytes[_weightOffset] & 0xff) << 8) | (bytes[_weightOffset + 1] & 0xff);
    double weightKg = rawWeight / 100.0;

    // Status byte: upper nibble = stable, lower nibble = unit
    final statusByte = bytes[_statusOffset];
    final isStable = ((statusByte & 0xf0) >> 4) != 0;
    final unitCode = statusByte & 0x0f;

    final unit = switch (unitCode) {
      1 => WeightUnit.kg,
      2 => WeightUnit.lb,
      4 => WeightUnit.jin,
      _ => WeightUnit.unknown,
    };

    // 3. Normalize the value to standard Kilograms
    if (unit == WeightUnit.lb) {
      weightKg = weightKg * 0.453592; // Convert Lb to Kg
    } else if (unit == WeightUnit.jin) {
      weightKg = weightKg * 0.5;      // 1 Jin is exactly 0.5 Kg
    }

    return WeightReading(
      weightKg: weightKg,
      isStable: isStable,
      unit: unit,
    );
  }

  // Usually not needed for a global Singleton, but good for cleanup on app exit
  void dispose() {
    stopListening();
    _weightController.close();
  }
}
