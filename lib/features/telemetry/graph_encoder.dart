import 'dart:typed_data';

class GraphOptimizer {
  /// Compresses the raw hardware data using a two-stage pipeline.
  static List<(int, double)> compress(
    List<(int, double)> rawData, {
    double flatlineEpsilon = 0.05, // kg
    double rdpEpsilon = 0.5,       // kg error tolerance for the curve
  }) {
    if (rawData.length <= 2) return rawData;

    // Stage 1: Prune redundant flat lines (e.g., long rest periods at 0kg)
    final step1 = _removeFlatlines(rawData, flatlineEpsilon);

    // Stage 2: Smooth out the noisy pull curves using RDP
    // final step2 = _rdp(step1, rdpEpsilon);

    return step1;
  }

  static List<(int, double)> _removeFlatlines(List<(int, double)> data, double epsilon) {
    final List<(int, double)> optimized = [data.first];

    for (int i = 1; i < data.length - 1; i++) {
      final prevY = optimized.last.$2;
      final currY = data[i].$2;
      final nextY = data[i + 1].$2;

      // If the line is virtually flat from the last saved point, 
      // through the current point, to the next point... drop the current point!
      if ((currY - prevY).abs() <= epsilon && (nextY - currY).abs() <= epsilon) {
        continue;
      }
      optimized.add(data[i]);
    }
    
    optimized.add(data.last);
    return optimized;
  }

  static List<(int, double)> _rdp(List<(int, double)> points, double epsilon) {
    if (points.length <= 2) return points;

    double maxError = 0.0;
    int maxIndex = 0;

    final p1 = points.first;
    final p2 = points.last;

    // Find the point that strays the furthest from the straight line between p1 and p2
    for (int i = 1; i < points.length - 1; i++) {
      final p = points[i];
      
      // Calculate where the Y value *should* be if it were a perfect straight line
      final yInt = p1.$2 + (p2.$2 - p1.$2) * (p.$1 - p1.$1) / (p2.$1 - p1.$1);
      
      // Calculate the vertical error
      final error = (p.$2 - yInt).abs();

      if (error > maxError) {
        maxError = error;
        maxIndex = i;
      }
    }

    // If the furthest point is outside our error tolerance, we must keep it.
    // We then recursively check the left and right halves!
    if (maxError > epsilon) {
      final left = _rdp(points.sublist(0, maxIndex + 1), epsilon);
      final right = _rdp(points.sublist(maxIndex), epsilon);
      
      // Merge results, dropping the duplicate middle point
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      // If the maximum error was tiny, the whole segment is basically a straight line!
      return [p1, p2];
    }
  }
}

/// Converts the list of tuples into a raw byte array (BLOB)
Uint8List encode(List<(int, double)> history) {
  // Allocate exactly 16 bytes per data point
  final byteData = ByteData(history.length * 16);
  int offset = 0;

  for (final sample in history) {
    // Using Endian.little ensures consistency across different devices
    byteData.setInt64(offset, sample.$1, Endian.little);
    byteData.setFloat64(offset + 8, sample.$2, Endian.little);
    offset += 16;
  }

  return byteData.buffer.asUint8List();
}

/// Converts the raw byte array (BLOB) back into a list of tuples
List<(int, double)> decode(Uint8List bytes) {
  final byteData = ByteData.sublistView(bytes);
  final List<(int, double)> history = [];

  // Read chunks of 16 bytes until we hit the end
  for (int i = 0; i < byteData.lengthInBytes; i += 16) {
    final timestampMs = byteData.getInt64(i, Endian.little);
    final weightKg = byteData.getFloat64(i + 8, Endian.little);
    history.add((timestampMs, weightKg));
  }

  return history;
}
