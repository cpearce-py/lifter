import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ─── LiveGraphController ──────────────────────────────────────────────────────

class LiveGraphController extends ChangeNotifier {
  LiveGraphController({
    this.yMax = 100.0,
    this.windowDuration = const Duration(seconds: 10),
  });

  final double yMax;

  /// How much time is visible across the full width of the graph.
  final Duration windowDuration;

  final Queue<(DateTime, double)> _samples = Queue();

  double _peakValue = 0;
  double get peakValue => _peakValue;

  double get currentValue =>
      _samples.isEmpty ? 0 : _samples.last.$2;

  /// Just write into the buffer. No notify, no rebuild.
  void addSample(double value) {
    if (value > _peakValue) _peakValue = value;
    _samples.addLast((DateTime.now(), value));
    _pruneOld();
  }

  void reset({bool resetPeak = false}) {
    _samples.clear();
    if (resetPeak) _peakValue = 0;
    notifyListeners(); // structural reset — tell graph to clear
  }

  void _pruneOld() {
    final cutoff = DateTime.now().subtract(windowDuration);
    while (_samples.isNotEmpty && _samples.first.$1.isBefore(cutoff)) {
      _samples.removeFirst();
    }
  }

  /// Snapshot for the painter — called on each tick, not on each sample.
  List<(DateTime, double)> get snapshot => _samples.toList(growable: false);
}

// ─── LiveGraph ────────────────────────────────────────────────────────────────

class LiveGraph extends StatefulWidget {
  const LiveGraph({
    super.key,
    required this.controller,
    required this.accentColor,
    this.showPeakLine = true,
    this.isRecording = false,
    this.targetFps = 30,
  });

  final LiveGraphController controller;
  final Color accentColor;
  final bool showPeakLine;
  final bool isRecording;
  final int targetFps;

  @override
  State<LiveGraph> createState() => _LiveGraphState();
}

class _LiveGraphState extends State<LiveGraph>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastDraw = Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onReset);
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final frameInterval =
        Duration(microseconds: (1000000 / widget.targetFps).round());
    if (elapsed - _lastDraw < frameInterval) return;
    _lastDraw = elapsed;
    setState(() {}); // pure time-driven redraw
  }

  void _onReset() => setState(() {}); // controller.reset() only

  @override
  void didUpdateWidget(LiveGraph old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onReset);
      widget.controller.addListener(_onReset);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    widget.controller.removeListener(_onReset);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.accentColor.withOpacity(0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: _GraphPainter(
            snapshot: widget.controller.snapshot,
            now: DateTime.now(),
            windowDuration: widget.controller.windowDuration,
            yMax: widget.controller.yMax,
            accentColor: widget.accentColor,
            peakValue: widget.showPeakLine ? widget.controller.peakValue : 0,
            isRecording: widget.isRecording,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

// ─── _GraphPainter ────────────────────────────────────────────────────────────

class _GraphPainter extends CustomPainter {
  const _GraphPainter({
    required this.snapshot,
    required this.now,
    required this.windowDuration,
    required this.yMax,
    required this.accentColor,
    required this.peakValue,
    required this.isRecording,
  });

  final List<(DateTime, double)> snapshot;
  final DateTime now;
  final Duration windowDuration;
  final double yMax;
  final Color accentColor;
  final double peakValue;
  final bool isRecording;

  /// Maps a sample timestamp to an X coordinate.
  /// Samples at exactly `now` are at the right edge.
  /// Samples `windowDuration` ago are at the left edge.
  double _timeToX(DateTime t, double left, double width) {
    final ageSecs = now.difference(t).inMicroseconds / 1e6;
    final windowSecs = windowDuration.inMicroseconds / 1e6;
    return left + width * (1 - ageSecs / windowSecs);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const hPad = 16.0;
    const vPad = 24.0;
    final chartW = w - hPad * 2;
    final chartH = h - vPad * 2;

    // ── Grid ─────────────────────────────────────────────────────────────────
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

    if (snapshot.isEmpty) return;

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
    final linePath = Path();
    final fillPath = Path();
    double lastX = hPad;
    double lastY = vPad + chartH;

    for (int i = 0; i < snapshot.length; i++) {
      final (t, value) = snapshot[i];
      final x = _timeToX(t, hPad, chartW);
      final y = vPad + chartH * (1 - (value / yMax).clamp(0, 1));

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath
          ..moveTo(x, vPad + chartH)
          ..lineTo(x, y);
      } else {
        final cpX = (lastX + x) / 2;
        linePath.cubicTo(cpX, lastY, cpX, y, x, y);
        fillPath.cubicTo(cpX, lastY, cpX, y, x, y);
      }
      lastX = x;
      lastY = y;
    }

    fillPath
      ..lineTo(lastX, vPad + chartH)
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

    // ── Live dot — anchored to the last sample's time position ─────────────
    if (isRecording) {
      var dotX = w - hPad;
      canvas.drawCircle(
          Offset(dotX, lastY), 7, Paint()..color = accentColor.withOpacity(0.25));
      canvas.drawCircle(
          Offset(dotX, lastY), 4, Paint()..color = accentColor);
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.now != now ||
      old.peakValue != peakValue ||
      old.isRecording != isRecording ||
      old.accentColor != accentColor;
}
