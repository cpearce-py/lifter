import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:visibility_detector/visibility_detector.dart';

// ─── LiveGraphController ──────────────────────────────────────────────────────

class LiveGraphController extends ChangeNotifier {
  LiveGraphController({
    this.yMax = 100.0,
    this.windowDuration = const Duration(seconds: 10),
  });

  final double yMax;
  double? _targetMin;
  double? _targetMax;

  double? get targetMin => _targetMin;
  double? get targetMax => _targetMax;

  /// How much time is visible across the full width of the graph.
  final Duration windowDuration;

  final Queue<(int, double)> _samples = Queue();

  double _peakValue = 0;
  double get peakValue => _peakValue;

  double get currentValue =>
      _samples.isEmpty ? 0 : _samples.last.$2;

  /// Expose the queue directly. No .toList() overhead!
  Queue<(int, double)> get samples => _samples;

  final Stopwatch _stopwatch = Stopwatch();
  int get currentGraphTimeMs => _stopwatch.elapsedMilliseconds;

  void setTargets({double? min, double? max}) {
    _targetMin = min;
    _targetMax = max;
    notifyListeners(); // Instantly update the graph zone
  }

  void setIsActive(bool active) {
    if (active) {
      _stopwatch.start();
    } else {
      _stopwatch.stop();
    }
  }

  /// Just write into the buffer. No notify, no rebuild.
  void addSample(double value) {
    if (!_stopwatch.isRunning) return;
    if (value > _peakValue) _peakValue = value;
    _samples.addLast((currentGraphTimeMs, value));
    _pruneOld();
  }

  void reset({bool resetPeak = false}) {
    _samples.clear();
    _stopwatch.reset();
    if (resetPeak) _peakValue = 0;
    notifyListeners(); // structural reset — tell graph to clear
  }

  void _pruneOld() {
    final cutoff = currentGraphTimeMs -
        windowDuration.inMilliseconds;
    while (_samples.isNotEmpty && _samples.first.$1 < cutoff) {
      _samples.removeFirst();
    }
  }
}

// ─── LiveGraph ────────────────────────────────────────────────────────────────

class LiveGraph extends StatefulWidget {
  const LiveGraph({
    super.key,
    required this.controller,
    required this.accentColor,
    this.showPeakLine = true,
    this.isActive = false,
    this.targetFps = 30,
  });

  final LiveGraphController controller;
  final Color accentColor;
  final bool showPeakLine;
  final bool isActive;
  final int targetFps;

  @override
  State<LiveGraph> createState() => _LiveGraphState();
}

class _LiveGraphState extends State<LiveGraph>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  
  // We use a ValueNotifier to convert our raw Ticker into a Listenable 
  // that the CustomPainter can safely listen to.
  final ValueNotifier<int> _frameTick = ValueNotifier(0);
  Duration _lastDraw = Duration.zero;
  
  late Listenable _repaintListenable;

  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    // Merge the frame tick and the controller. 
    // This way, the graph repaints on a timer AND when controller.reset() is called.
    _repaintListenable = Listenable.merge([_frameTick, widget.controller]);
    
    _ticker = createTicker(_onTick);
    _syncActiveState();
  }

  void _syncActiveState() {
    widget.controller.setIsActive(widget.isActive);
    final shouldDrawUi = widget.isActive && _isVisible;
    if (shouldDrawUi) {
      if (!_ticker.isTicking) {
        _lastDraw = Duration.zero;
        _ticker.start();
      }
    } else {
      if (_ticker.isTicking) _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final frameInterval =
        Duration(microseconds: (1000000 / widget.targetFps).round());
    if (elapsed - _lastDraw < frameInterval) return;
    _lastDraw = elapsed;
    _frameTick.value++; 
  }

  @override
  void didUpdateWidget(LiveGraph old) {
    super.didUpdateWidget(old);
    
    if (old.isActive != widget.isActive) {
      _syncActiveState(); 
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frameTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('live-graph-detector'),
      onVisibilityChanged: (info) {
        final currentlyVisible = info.visibleFraction > 0;
        if (_isVisible != currentlyVisible) {
          _isVisible = currentlyVisible;
          _syncActiveState();
          }
        },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.accentColor.withOpacity(0.1), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CustomPaint(
            painter: _GraphPainter(
              repaint: _repaintListenable,
              controller: widget.controller,
              accentColor: widget.accentColor,
              showPeakLine: widget.showPeakLine,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

// ─── _GraphPainter ────────────────────────────────────────────────────────────

class _GraphPainter extends CustomPainter {
  const _GraphPainter({
    required Listenable repaint,
    required this.controller,
    required this.accentColor,
    required this.showPeakLine,
  }) : super(repaint: repaint);

  final LiveGraphController controller;
  final Color accentColor;
  final bool showPeakLine;

  double _timeToX(int tMs, double left, double width, int nowMs) {
    final ageSecs = (nowMs - tMs) / 1000.0;
    final windowSecs = controller.windowDuration.inMilliseconds / 1000.0;
    return left + width * (1 - ageSecs / windowSecs);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final nowMs = controller.currentGraphTimeMs;
    final yMax = controller.yMax;
    final peakValue = showPeakLine ? controller.peakValue : 0.0;
    final samples = controller.samples;
    final targetMin = controller.targetMin;
    final targetMax = controller.targetMax;

    final w = size.width;
    final h = size.height;
    const hPad = 16.0;
    const vPad = 24.0;
    final chartW = w - hPad * 2;
    final chartH = h - vPad * 2;

    final colorBelow = accentColor;
    const colorInRange = Color(0xFF4CAF50); 
    const colorAbove = Color(0xFFFF6B6B);   

    // ── Grid ─────────────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = vPad + chartH * (1 - i / 4);
      canvas.drawLine(Offset(hPad, y), Offset(w - hPad, y), gridPaint);
      
      // Reverted to clean integers!
      final labelText = (yMax * i / 4).toStringAsFixed(0);

      final tp = TextPainter(
        text: TextSpan(
          text: labelText,
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

    // ── Target Zone Background ───────────────────────────────────────────────
    if (targetMin != null && targetMax != null) {
      final targetTopY = vPad + chartH * (1 - (targetMax! / yMax).clamp(0.0, 1.0));
      final targetBottomY = vPad + chartH * (1 - (targetMin! / yMax).clamp(0.0, 1.0));
      
      final zoneRect = Rect.fromLTRB(hPad, targetTopY, w - hPad, targetBottomY);
      canvas.drawRect(
        zoneRect, 
        Paint()..color = colorInRange.withOpacity(0.333),
      );
    }

    if (samples.isEmpty) return;

    // ── Peak line ─────────────────────────────────────────────────────────────
    if (peakValue > 0) {
      // Kept the clamp here so it doesn't float above the graph!
      final peakY = vPad + chartH * (1 - (peakValue / yMax).clamp(0.0, 1.0));
      
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
          ..color = colorAbove.withOpacity(0.4)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }

    // ── Line + fill ───────────────────────────────────────────────────────────
    final linePath = Path();
    final fillPath = Path();
    double lastX = hPad;
    double lastY = vPad + chartH;

    bool isFirst = true;

    for (final sample in samples) {
      final t = sample.$1;
      final value = sample.$2;
      
      final x = _timeToX(t, hPad, chartW, nowMs);
      // Kept the clamp here so the line doesn't break out of the box!
      final y = vPad + chartH * (1 - (value / yMax).clamp(0.0, 1.0));

      if (isFirst) {
        linePath.moveTo(x, y);
        fillPath
          ..moveTo(x, vPad + chartH)
          ..lineTo(x, y);
        isFirst = false;
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

    Paint linePaint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (targetMin != null && targetMax != null) {
      final stopMax = (1 - targetMax! / yMax).clamp(0.0, 1.0);
      final stopMin = (1 - targetMin! / yMax).clamp(0.0, 1.0);

      linePaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [
          0.0, stopMax, 
          stopMax, stopMin, 
          stopMin, 1.0,
        ],
        colors: [
          colorAbove, colorAbove,
          colorInRange, colorInRange,
          colorBelow, colorBelow,
        ],
      ).createShader(Rect.fromLTWH(hPad, vPad, chartW, chartH));
    } else {
      linePaint.color = accentColor;
    }

    canvas.drawPath(linePath, linePaint);

    // ── Live dot ──────────────────────────────────────────────────────────────
    var dotX = w - hPad;
    
    Color currentDotColor = accentColor;
    if (targetMin != null && targetMax != null) {
      final lastValue = samples.last.$2;
      if (lastValue > targetMax!) {currentDotColor = colorAbove;}
      else if (lastValue >= targetMin!) {currentDotColor = colorInRange;}
      else {currentDotColor = colorBelow;}
    }

    canvas.drawCircle(Offset(dotX, lastY), 7, Paint()..color = currentDotColor.withOpacity(0.25));
    canvas.drawCircle(Offset(dotX, lastY), 4, Paint()..color = currentDotColor);
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.accentColor != accentColor ||
      old.showPeakLine != showPeakLine ||
      old.controller.targetMin != controller.targetMin ||
      old.controller.targetMax != controller.targetMax ||
      old.controller != controller;
}
