import 'dart:math';
import 'package:flutter/material.dart';

// ─── LiveGraphController ──────────────────────────────────────────────────────
// Create one per session page, pass it to LiveGraph.
// Call addSample() with each incoming value (from BLE or a mock timer).
// Call reset() to clear the graph (e.g. between reps).

class LiveGraphController extends ChangeNotifier {
  LiveGraphController({
    this.maxPoints = 200,
    this.yMax = 100.0,
  });

  final int maxPoints;
  final double yMax;

  final List<double> _data = [];
  double _peakValue = 0;
  double _currentValue = 0;

  List<double> get data => List.unmodifiable(_data);
  double get peakValue => _peakValue;
  double get currentValue => _currentValue;

  void addSample(double value) {
    _currentValue = value;
    if (value > _peakValue) _peakValue = value;
    _data.add(value);
    if (_data.length > maxPoints) _data.removeAt(0);
    notifyListeners();
  }

  /// Clears the graph while preserving the overall peak.
  void reset({bool resetPeak = false}) {
    _data.clear();
    _currentValue = 0;
    if (resetPeak) _peakValue = 0;
    notifyListeners();
  }
}

// ─── LiveGraph ────────────────────────────────────────────────────────────────
// A pure display widget. Feed it a controller and it redraws on every sample.
//
// Usage:
//   LiveGraph(
//     controller: _graphController,
//     accentColor: Color(0xFF47C8FF),
//     showPeakLine: true,
//   )

class LiveGraph extends StatelessWidget {
  const LiveGraph({
    super.key,
    required this.controller,
    required this.accentColor,
    this.showPeakLine = true,
    this.isRecording = false,
  });

  final LiveGraphController controller;
  final Color accentColor;
  final bool showPeakLine;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CustomPaint(
            painter: _GraphPainter(
              data: controller.data,
              maxPoints: controller.maxPoints,
              yMax: controller.yMax,
              accentColor: accentColor,
              peakValue: showPeakLine ? controller.peakValue : 0,
              isRecording: isRecording,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

// ─── GraphPainter ─────────────────────────────────────────────────────────────

class _GraphPainter extends CustomPainter {
  const _GraphPainter({
    required this.data,
    required this.maxPoints,
    required this.yMax,
    required this.accentColor,
    required this.peakValue,
    required this.isRecording,
  });

  final List<double> data;
  final int maxPoints;
  final double yMax;
  final Color accentColor;
  final double peakValue;
  final bool isRecording;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const hPad = 16.0;
    const vPad = 24.0;
    final chartW = w - hPad * 2;
    final chartH = h - vPad * 2;

    // ── Grid lines ────────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = vPad + chartH * (1 - i / 4);
      canvas.drawLine(Offset(hPad, y), Offset(w - hPad, y), gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: (yMax * i / 4).toStringAsFixed(0),
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withOpacity(0.2),
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }

    if (data.isEmpty) return;

    // ── Peak line ─────────────────────────────────────────────────────────────
    if (peakValue > 0) {
      final peakY = vPad + chartH * (1 - peakValue / yMax);
      final dashPath = Path();
      double x = hPad;
      bool on = true;
      while (x < w - hPad) {
        if (on) {
          dashPath.moveTo(x, peakY);
          dashPath.lineTo(min(x + 6, w - hPad), peakY);
        }
        x += 10;
        on = !on;
      }
      canvas.drawPath(
        dashPath,
        Paint()
          ..color = const Color(0xFFFF6B6B).withOpacity(0.4)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }

    // ── Line + fill ───────────────────────────────────────────────────────────
    final xStep = chartW / (maxPoints - 1);
    final startX = hPad + (maxPoints - data.length) * xStep;

    final linePath = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = startX + i * xStep;
      final y = vPad + chartH * (1 - data[i] / yMax);
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath
          ..moveTo(x, h - vPad)
          ..lineTo(x, y);
      } else {
        final prevX = startX + (i - 1) * xStep;
        final prevY = vPad + chartH * (1 - data[i - 1] / yMax);
        final cpX = (prevX + x) / 2;
        linePath.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    final lastX = startX + (data.length - 1) * xStep;
    fillPath
      ..lineTo(lastX, h - vPad)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withOpacity(0.25),
            accentColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(hPad, vPad, chartW, chartH))
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = accentColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Live dot ──────────────────────────────────────────────────────────────
    if (isRecording && data.isNotEmpty) {
      final dotY = vPad + chartH * (1 - data.last / yMax);
      canvas.drawCircle(Offset(lastX, dotY), 7,
          Paint()..color = accentColor.withOpacity(0.25));
      canvas.drawCircle(
          Offset(lastX, dotY), 4, Paint()..color = accentColor);
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.data != data ||
      old.peakValue != peakValue ||
      old.isRecording != isRecording;
}