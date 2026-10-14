import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum WeightUnit { kg, lb, stone, jin, unknown }

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

/// Where the scale connection is at, for showing the user.
enum ScaleStatus {
  /// Nothing is listening for the scale.
  idle,
  bluetoothOff,

  /// The app hasn't been allowed to use Bluetooth.
  unauthorized,

  /// This device has no Bluetooth.
  unavailable,

  /// Scanning, but no reading has come in lately.
  searching,

  /// Readings are coming in.
  receiving,
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

  /// How long without a reading before we say we're searching again.
  static const _readingTimeout = Duration(seconds: 4);

  final _weightController = StreamController<WeightReading>.broadcast();
  Stream<WeightReading> get weightStream => _weightController.stream;

  final _statusController = StreamController<ScaleStatus>.broadcast();
  ScaleStatus _status = ScaleStatus.idle;
  ScaleStatus get status => _status;
  Stream<ScaleStatus> get statusStream => _statusController.stream;

  final _pairedController = StreamController<String>.broadcast();

  /// Emits a device id when readings lock onto a scale that wasn't paired.
  Stream<String> get pairedStream => _pairedController.stream;

  /// Only readings from this scale are used, so another one nearby (a
  /// training partner's) can't mix in. Null takes the first scale heard,
  /// which then becomes the paired one.
  String? pairedDeviceId;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  Timer? _readingTimer;

  /// How many screens and engines want readings. The scan runs while any
  /// do, so one leaving can't cut off another.
  int _listeners = 0;

  /// The scan being started, so overlapping starts share one.
  Future<void>? _starting;

  Future<void> startListening() {
    _listeners++;
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  void stopListening() {
    if (_listeners == 0) return;
    _listeners--;
    if (_listeners == 0) _stop();
  }

  Future<void> _start() async {
    if (_scanSubscription != null) return;

    // Follows the adapter for as long as we're listening, so turning
    // Bluetooth off (or back on) mid-session shows up.
    _adapterSubscription ??= FlutterBluePlus.adapterState.listen((state) {
      switch (state) {
        case BluetoothAdapterState.on:
          if (_status != ScaleStatus.receiving) _setStatus(ScaleStatus.searching);
          // Back on (or just allowed) after the scan stopped or never ran.
          if (_listeners > 0 && _scanSubscription == null) {
            _starting ??= _start().whenComplete(() => _starting = null);
          }
        case BluetoothAdapterState.unauthorized:
          _setStatus(ScaleStatus.unauthorized);
        case BluetoothAdapterState.unavailable:
          _setStatus(ScaleStatus.unavailable);
        case BluetoothAdapterState.off || BluetoothAdapterState.turningOff:
          // The scan dies with the adapter; it's restarted when it's back.
          _scanSubscription?.cancel();
          _scanSubscription = null;
          _readingTimer?.cancel();
          _setStatus(ScaleStatus.bluetoothOff);
        default:
          break;
      }
    });

    // Waits here while Bluetooth is off, and carries on once it's turned on.
    final state = await FlutterBluePlus.adapterState
      .where((s) => 
        s == BluetoothAdapterState.on ||
        s == BluetoothAdapterState.unauthorized ||
        s == BluetoothAdapterState.unavailable)
      .first;

    if (_listeners == 0) return; // Everyone left while we waited.
    if (state != BluetoothAdapterState.on) {
      debugPrint('[BleManager] Bluetooth unavailable');
      return;
    }

    await FlutterBluePlus.startScan(
      continuousUpdates: true,
      removeIfGone: const Duration(seconds: 5),
    );

    if (_listeners == 0) {
      // Stopped while the scan was starting.
      await FlutterBluePlus.stopScan();
      return;
    }

    _setStatus(ScaleStatus.searching);
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        _processResult(result);
      }
    });
  }

  void _stop() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _adapterSubscription?.cancel();
    _adapterSubscription = null;
    _readingTimer?.cancel();
    _setStatus(ScaleStatus.idle);
  }

  void _setStatus(ScaleStatus status) {
    if (status == _status) return;
    _status = status;
    _statusController.add(status);
  }

  void _processResult(ScanResult result) {
    final mfrData = result.advertisementData.manufacturerData[_manufacturerId];
    if (mfrData == null || mfrData.length <= _statusOffset) return;

    final deviceId = result.device.remoteId.str;
    if (pairedDeviceId == null) {
      pairedDeviceId = deviceId;
      _pairedController.add(deviceId);
    } else if (deviceId != pairedDeviceId) {
      return; // Someone else's scale.
    }

    final reading = decode(mfrData);
    if (kDebugMode) {
      // Raw packet next to what we made of it, for checking a scale's
      // unit codes. Debug builds only.
      final hex = mfrData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      debugPrint(
        '[BleManager] ${mfrData.length}B [$hex] unit=${mfrData[_statusOffset] & 0x0f} '
        '-> ${reading?.weightKg.toStringAsFixed(2)} kg (${reading?.unit.name})',
      );
    }
    if (reading != null) {
      _weightController.add(reading);
      _setStatus(ScaleStatus.receiving);
      _readingTimer?.cancel();
      _readingTimer = Timer(_readingTimeout, () {
        if (_scanSubscription != null) _setStatus(ScaleStatus.searching);
      });
    }
  }

  /// Reads a weight out of the scale's manufacturer data. Null if [bytes]
  /// is too short to hold one.
  @visibleForTesting
  static WeightReading? decode(List<int> bytes) {
    if (bytes.length < _statusOffset + 1) return null;

    // Weight: 16-bit big-endian at offset 10, unit is 0.01 kg
    final rawWeight =
        ((bytes[_weightOffset] & 0xff) << 8) | (bytes[_weightOffset + 1] & 0xff);
    double weightKg = rawWeight / 100.0;

    // Status byte: upper nibble = stable, lower nibble = unit
    final statusByte = bytes[_statusOffset];
    final isStable = ((statusByte & 0xf0) >> 4) != 0;
    final unitCode = statusByte & 0x0f;

    // Weiheng's sample code lists 1 kg, 2 lb, 3 stone, 4 jin. Some WH-C06
    // units send 0 when set to pounds too (Hang Ten saw the same).
    final unit = switch (unitCode) {
      1 => WeightUnit.kg,
      0 || 2 => WeightUnit.lb,
      3 => WeightUnit.stone,
      4 => WeightUnit.jin,
      _ => WeightUnit.unknown,
    };

    // 3. Normalize the value to standard Kilograms
    if (unit == WeightUnit.lb) {
      weightKg = weightKg * 0.453592; // Convert Lb to Kg
    } else if (unit == WeightUnit.stone) {
      weightKg = weightKg * 6.35029;  // 1 st is 14 lb
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
    _listeners = 0;
    _stop();
    _weightController.close();
    _statusController.close();
    _pairedController.close();
  }
}
