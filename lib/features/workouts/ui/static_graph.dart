import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/measurements/unit_converter.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/telemetry/graph_encoder.dart';

// ─── HistoricalGraph ─────────────────────────────────────────────────────────


class HistoricalGraph extends ConsumerStatefulWidget {
  final Uint8List? graphData;
  final Color accentColor;
  final double maxWeight;

  const HistoricalGraph({
    super.key,
    required this.graphData,
    required this.accentColor,
    required this.maxWeight,
  });

  @override
  ConsumerState<HistoricalGraph> createState() => _HistoricalGraphState();
}

class _HistoricalGraphState extends ConsumerState<HistoricalGraph> {
  final TransformationController _transformController = TransformationController();
  
  // State to handle fading out the interaction hint icon
  bool _userHasInteracted = false;
  bool _iconVisible = true;

  static const double hPad = 16.0;
  // We increase bottom padding significantly to make room for the time labels
  static const double vPadTop = 24.0;
  static const double vPadBottom = 32.0; 

  @override
  void initState() {
    super.initState();
    // Start showing the icon immediately
    _iconVisible = true;
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    // If this is the very first interaction, flag it and start the fade out.
    if (!_userHasInteracted) {
      _userHasInteracted = true;
      // Fade out on the next frame to prevent stutter
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _iconVisible = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.graphData == null || widget.graphData!.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: context.inputBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.accentColor.withOpacity(0.1), width: 1),
        ),
        child: Center(
          child: Text("No graph data available", style: TextStyle(color: context.textMuted)),
        ),
      );
    }

    final history = decode(widget.graphData!);
    if (history.isEmpty) return const SizedBox();

    final useLbs = ref.watch(userSettingsProvider.select((s) => s.useLbs));

    double yMax = 100.0;
    if (widget.maxWeight > 0) {
      final weightFactor = (widget.maxWeight / 100.0).clamp(0.0, 1.0);
      final multiplier = 1.20 - (0.10 * weightFactor);
      yMax = widget.maxWeight * multiplier;
    }

    return Container(
      decoration: BoxDecoration(
        color: context.inputBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.accentColor.withOpacity(0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. The Dynamic Visual Graph + Axis Layer
            AnimatedBuilder(
              animation: _transformController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _HistoricalGraphPainter(
                    history: history,
                    yMax: yMax,
                    accentColor: widget.accentColor,
                    useLbs: useLbs,
                    textColor: context.textMuted,
                    gridColor: context.textPrimary.withValues(alpha: 0.05),
                    transformMatrix: _transformController.value,
                    hPad: hPad,
                    vPadTop: vPadTop,
                    vPadBottom: vPadBottom,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),

            // 2. The Invisible Gesture Catcher
            Positioned(
              left: hPad,
              right: hPad,
              top: vPadTop,
              bottom: vPadBottom, // Catcher matches the chart area exactly
              child: InteractiveViewer(
                transformationController: _transformController,
                panAxis: PanAxis.horizontal,
                minScale: 1.0,
                maxScale: 15.0, // Increased zoom depth for analytical look
                clipBehavior: Clip.none, 
                onInteractionUpdate: _onInteractionUpdate, // Catch the first move!
                child: const SizedBox.expand(),
              ),
            ),

            // 3. The Interaction Hint Icon 
            Positioned(
              top: 12,
              right: 12,
              child: IgnorePointer( // Let gestures pass through to the catcher
                child: AnimatedOpacity(
                  opacity: _iconVisible ? 0.7 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pinch, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "Swipe to pan / Zoom", 
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _HistoricalGraphPainter ─────────────────────────────────────────────────

class _HistoricalGraphPainter extends CustomPainter {
  const _HistoricalGraphPainter({
    required this.history,
    required this.yMax,
    required this.accentColor,
    required this.useLbs,
    required this.textColor,
    required this.gridColor,
    required this.transformMatrix,
    required this.hPad,
    required this.vPadTop,
    required this.vPadBottom,
  });

  final List<(int, double)> history;
  final double yMax;
  final Color accentColor;
  final bool useLbs;
  final Color textColor;
  final Color gridColor;
  final Matrix4 transformMatrix;
  final double hPad;
  final double vPadTop;
  final double vPadBottom;

  double _timeToX(int tMs, double left, double width, int startMs, int totalMs, double scale, double dx) {
    if (totalMs <= 0) return left;
    final progress = (tMs - startMs) / totalMs;
    final scaledWidth = width * scale;
    return left + dx + (scaledWidth * progress);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final chartW = w - hPad * 2;
    // h - topPad - bottomPad
    final chartH = h - vPadTop - vPadBottom;

    final startMs = history.first.$1;
    final endMs = history.last.$1;
    final totalMs = endMs - startMs;

    final double scale = transformMatrix.entry(0, 0); 
    final double dx = transformMatrix.getTranslation().x; 

    // ── Grid & Y-Axis Labels (Static) ────────────────────────────────────────
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = vPadTop + chartH * (1 - i / 4);
      canvas.drawLine(Offset(hPad, y), Offset(w - hPad, y), gridPaint);
      
      double rawValue = yMax * i / 4;
      double displayValue = useLbs ? kgToLbs(rawValue) : rawValue;
      final labelText = displayValue.toStringAsFixed(0);

      final tp = TextPainter(
        text: TextSpan(
          text: labelText,
          style: TextStyle(fontSize: 9, color: textColor, fontWeight: FontWeight.w500,),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }

    // Save canvas, clip to chart area to avoid bleed-through
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(hPad, 0, chartW, size.height));

    // Calculate a stable label interval (in seconds) that changes based on zoom level
    // 1x zoom = 60s intervals. 10x zoom = 6s intervals.
    double baseInterval = 60.0;
    double dynamicIntervalSeconds = (baseInterval / scale).clamp(5.0, 300.0);
    
    // Snapping the interval to standard time numbers looks cleaner
    if (dynamicIntervalSeconds > 60) {
      dynamicIntervalSeconds = (dynamicIntervalSeconds / 60).round() * 60.0;
    } else if (dynamicIntervalSeconds > 10) {
      dynamicIntervalSeconds = (dynamicIntervalSeconds / 10).round() * 10.0;
    } else {
      dynamicIntervalSeconds = (dynamicIntervalSeconds / 5).round() * 5.0;
    }

    // Paint the small hash marks
    final axisPaint = Paint()
      ..color = textColor.withOpacity(0.3)
      ..strokeWidth = 1;

    for (int tSec = 0; tSec <= totalMs / 1000.0; tSec++) {
      // Determine if this second mark needs a line drawn
      final isModuloInterval = tSec % dynamicIntervalSeconds == 0;
      
      // If not aModulo interval, we can draw smaller hash marks every X seconds, 
      // but only if zoomed in enough. For simplicity, just labeling here.
      if (isModuloInterval) {
        // Find the specific timestamp to map it to the moving X-axis
        int targetMs = startMs + (tSec * 1000);
        final x = _timeToX(targetMs, hPad, chartW, startMs, totalMs, scale, dx);

        // Optimization: Only layout and paint if the label is actually on screen!
        if (x > hPad - 20 && x < w - hPad + 20) {
          
          // Draw the vertical tick line at the base of the chart
          canvas.drawLine(Offset(x, vPadTop + chartH), Offset(x, vPadTop + chartH + 4), axisPaint);

          // Format the time as M:SS
          final minutes = tSec ~/ 60;
          final seconds = tSec % 60;
          final labelText = '$minutes:${seconds.toString().padLeft(2, '0')}';

          final tpTime = TextPainter(
            text: TextSpan(
              text: labelText,
              style: TextStyle(fontSize: 9, color: textColor, fontWeight: FontWeight.w500,),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          
          // Draw the text centered under the tick line
          tpTime.paint(canvas, Offset(x - tpTime.width / 2, vPadTop + chartH + 8));
        }
      }
    }

    // ── Force Curve Line + fill ──────────────────────────────────────────
    final linePath = Path();
    final fillPath = Path();
    double lastX = hPad;
    double lastY = vPadTop + chartH;
    bool isFirst = true;

    for (final sample in history) {
      final t = sample.$1;
      final value = sample.$2;
      
      final x = _timeToX(t, hPad, chartW, startMs, totalMs, scale, dx);
      final y = vPadTop + chartH * (1 - (value / yMax).clamp(0.0, 1.0));

      if (isFirst) {
        linePath.moveTo(x, y);
        fillPath..moveTo(x, vPadTop + chartH)..lineTo(x, y);
        isFirst = false;
      } else {
        final cpX = (lastX + x) / 2;
        linePath.cubicTo(cpX, lastY, cpX, y, x, y);
        fillPath.cubicTo(cpX, lastY, cpX, y, x, y);
      }
      lastX = x;
      lastY = y;
    }

    fillPath..lineTo(lastX, vPadTop + chartH)..close();

    // Fill Gradient (Anchored to screen, doesn't move when panning)
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
        ).createShader(Rect.fromLTWH(hPad, vPadTop, chartW, chartH))
        ..style = PaintingStyle.fill,
    );

    // Line Stroke
    Paint linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Restore canvas from clipping
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HistoricalGraphPainter old) =>
      old.accentColor != accentColor ||
      old.useLbs != useLbs || 
      old.textColor != textColor ||
      old.yMax != yMax ||
      old.transformMatrix != transformMatrix || 
      old.history != history;
}
