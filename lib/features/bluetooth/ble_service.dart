import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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

enum WeightUnit { kg, lb, jin, unknown }

class WeiHengC06Service {
  // From manufacturer source: ManufacturerId = 256
  static const int _manufacturerId = 256;
  // Offsets within manufacturer-specific data
  static const int _weightOffset = 10;
  static const int _statusOffset = 14;

  final _weightController = StreamController<WeightReading>.broadcast();
  Stream<WeightReading> get weightStream => _weightController.stream;

  StreamSubscription? _scanSubscription;

  Future<void> startListening() async {
    final state = await FlutterBluePlus.adapterState
      .where((s) => 
        s == BluetoothAdapterState.on ||
        s == BluetoothAdapterState.unauthorized ||
        s == BluetoothAdapterState.unavailable)
      .first;

    if (state != BluetoothAdapterState.on) {
      debugPrint('[WeiHengC06Service] Bluetooth unavailable');
      return;
    }

    FlutterBluePlus.startScan(
      continuousUpdates: true,
      removeIfGone: const Duration(seconds: 5),
    );

    FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        _processResult(result);
      }
    });
  }

  void stopListening() {
    FlutterBluePlus.stopScan();
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
    final weightKg = rawWeight / 100.0;

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

    return WeightReading(
      weightKg: weightKg,
      isStable: isStable,
      unit: unit,
    );
  }

  void dispose() {
    stopListening();
    _weightController.close();
  }
}

