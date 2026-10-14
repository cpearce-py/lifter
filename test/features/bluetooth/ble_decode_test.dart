import 'package:flutter_test/flutter_test.dart';
import 'package:lifter/features/bluetooth/ble_manager.dart';

/// Manufacturer data as the scale sends it: the weight in 0.01 units,
/// big-endian at bytes 10-11, and a status byte at 14 (upper nibble set
/// when stable, lower nibble the unit).
List<int> advert({required int raw, required int status}) => [
      ...List.filled(10, 0),
      (raw >> 8) & 0xff,
      raw & 0xff,
      0,
      0,
      status,
    ];

void main() {
  test('reads a stable kg weight', () {
    final reading = BleManager.decode(advert(raw: 4250, status: 0x11))!;
    expect(reading.weightKg, 42.5);
    expect(reading.unit, WeightUnit.kg);
    expect(reading.isStable, isTrue);
  });

  test('converts lb and jin to kg', () {
    final lb = BleManager.decode(advert(raw: 10000, status: 0x02))!;
    expect(lb.weightKg, closeTo(45.3592, 1e-4));
    expect(lb.isStable, isFalse);

    final jin = BleManager.decode(advert(raw: 8000, status: 0x14))!;
    expect(jin.weightKg, 40);
  });

  test('reads unit code 0 as pounds, as some WH-C06 units send', () {
    // The scale shows 10.00 lb: that's 4.54 kg, not 10 kg.
    final reading = BleManager.decode(advert(raw: 1000, status: 0x10))!;
    expect(reading.unit, WeightUnit.lb);
    expect(reading.weightKg, closeTo(4.5359, 1e-4));
  });

  test('converts stone to kg', () {
    final reading = BleManager.decode(advert(raw: 200, status: 0x03))!;
    expect(reading.unit, WeightUnit.stone);
    expect(reading.weightKg, closeTo(12.70058, 1e-4));
  });

  test('leaves unknown unit codes as kg', () {
    final reading = BleManager.decode(advert(raw: 1000, status: 0x07))!;
    expect(reading.unit, WeightUnit.unknown);
    expect(reading.weightKg, 10);
  });

  test('ignores data too short to hold a reading', () {
    expect(BleManager.decode(List.filled(14, 0)), isNull);
  });
}
