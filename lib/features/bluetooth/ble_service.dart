import 'package:flutter/foundation.dart';

// ─── BleService ───────────────────────────────────────────────────────────────
// Owns all Bluetooth state and exposes it as a ChangeNotifier so any widget
// in the tree can listen and rebuild when the connection changes.
//
// Usage:
//   final ble = BleService();          // create once at the top of your app
//   ListenableBuilder(listenable: ble, builder: (context, _) { ... })
//
// Wire up real BLE by replacing the three stub methods:
//   startScan(), _connectToDevice(), _disconnectFromDevice()

enum BleState { disconnected, scanning, connected }

class BleService extends ChangeNotifier {
  BleState _state = BleState.disconnected;
  String? _connectedDeviceName;

  // ── Public read-only state ─────────────────────────────────────────────────

  BleState get state => _state;
  String? get connectedDeviceName => _connectedDeviceName;
  bool get isConnected => _state == BleState.connected;
  bool get isScanning => _state == BleState.scanning;

  // ── Simulated nearby devices ───────────────────────────────────────────────
  // Replace with a stream from your BLE package (e.g. flutter_blue_plus).
  List<String> _scannedDevices = [];
  List<String> get scannedDevices => List.unmodifiable(_scannedDevices);

  static const _mockDevices = ['Weiheng Scale', 'Weiheng Pro', 'Weiheng Lite'];

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Start scanning for nearby devices.
  /// Replace the body with a real BLE scan (e.g. FlutterBluePlus.startScan).
  Future<void> startScan() async {
    if (_state == BleState.scanning) return;
    _scannedDevices = [];
    _state = BleState.scanning;
    notifyListeners();

    // ── Stub: simulates a 1.5 s scan then returns mock results ────────────
    await Future.delayed(const Duration(milliseconds: 1500));
    _scannedDevices = _mockDevices;
    // ── End stub ───────────────────────────────────────────────────────────

    _state = BleState.disconnected;
    notifyListeners();
  }

  /// Connect to a device by name.
  /// Replace with real BLE connection logic.
  Future<void> connect(String deviceName) async {
    await _connectToDevice(deviceName);
    _connectedDeviceName = deviceName;
    _state = BleState.connected;
    notifyListeners();
  }

  /// Disconnect from the current device.
  Future<void> disconnect() async {
    await _disconnectFromDevice();
    _connectedDeviceName = null;
    _state = BleState.disconnected;
    notifyListeners();
  }

  // ── Private BLE stubs (swap these for real implementation) ────────────────

  Future<void> _connectToDevice(String name) async {
    // TODO: replace with real BLE connect, e.g.:
    //   final device = scannedDevices.firstWhere((d) => d.name == name);
    //   await device.connect();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _disconnectFromDevice() async {
    // TODO: replace with real BLE disconnect, e.g.:
    //   await _currentDevice?.disconnect();
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
