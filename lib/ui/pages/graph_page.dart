import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lifter/ble/ble_service.dart';

// ─── GraphPage ────────────────────────────────────────────────────────────────
// Shows a live-updating force/load graph.
// Currently driven by a mock data stream — swap _startMockStream() for a real
// BLE data subscription when your sensor integration is ready.

class GraphPage extends StatefulWidget {
  const GraphPage({super.key, required this.bleService});

  final BleService bleService;

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage>
    with SingleTickerProviderStateMixin {
  static const _accentColor = Color(0xFF47C8FF);
  static const _maxPoints = 200;      // number of samples visible in the window
  static const _tickMs = 50;          // sample interval in milliseconds (20 Hz)
  static const _yMax = 100.0;         // Y-axis ceiling (kg / units)

  final List<double> _data = [];
  double _peakValue = 0;
  double _currentValue = 0;
  bool _isRecording = false;

  Timer? _mockTimer;
  double _mockPhase = 0;
  final _rng = Random();

  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  // ── Mock stream ───────────────────────────────────────────────────────────
  // Replace this entire method with a real BLE subscription, e.g.:
  //   widget.bleService.dataStream.listen((sample) => _addSample(sample));
  void _startMockStream() {
    _mockTimer = Timer.periodic(
      const Duration(milliseconds: _tickMs),
      (_) {
        _mockPhase += 0.05;
        // Simulate a force curve: sine base + noise + occasional spike
        final base = 35 + 25 * sin(_mockPhase);
        final noise = (_rng.nextDouble() - 0.5) * 6;
        final spike = _rng.nextDouble() > 0.97 ? _rng.nextDouble() * 20 : 0;
        _addSample((base + noise + spike).clamp(0, _yMax));
      },
    );
  }

  void _stopStream() {
    _mockTimer?.cancel();
    _mockTimer = null;
  }

  void _addSample(double value) {
    setState(() {
      _currentValue = value;
      if (value > _peakValue) _peakValue = value;
      _data.add(value);
      if (_data.length > _maxPoints) _data.removeAt(0);
    });
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
    if (_isRecording) {
      _peakValue = 0;
      _startMockStream();
    } else {
      _stopStream();
    }
  }

  void _reset() {
    _stopStream();
    setState(() {
      _isRecording = false;
      _data.clear();
      _peakValue = 0;
      _currentValue = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildChart()),
          _buildStatsRow(),
          _buildControls(context),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 28, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIVE DATA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: _accentColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Force Graph',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: Color(0xFFF0F0F0),
                  ),
                ),
              ],
            ),
          ),
          // Recording indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isRecording
                  ? const Color(0xFFFF6B6B).withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isRecording
                    ? const Color(0xFFFF6B6B).withOpacity(0.4)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulsingDot(active: _isRecording),
                const SizedBox(width: 6),
                Text(
                  _isRecording ? 'REC' : 'IDLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: _isRecording
                        ? const Color(0xFFFF6B6B)
                        : Colors.white30,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Chart ──────────────────────────────────────────────────────────────────

  Widget _buildChart() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D14),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: _accentColor.withOpacity(0.1), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CustomPaint(
            painter: _GraphPainter(
              data: List.unmodifiable(_data),
              maxPoints: _maxPoints,
              yMax: _yMax,
              accentColor: _accentColor,
              peakValue: _peakValue,
              isRecording: _isRecording,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              label: 'Current',
              value: _currentValue.toStringAsFixed(1),
              unit: 'kg',
              color: _accentColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatChip(
              label: 'Peak',
              value: _peakValue.toStringAsFixed(1),
              unit: 'kg',
              color: const Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatChip(
              label: 'Samples',
              value: _data.length.toString(),
              unit: '',
              color: const Color(0xFFB47FFF),
            ),
          ),
        ],
      ),
    );
  }

  // ── Controls ───────────────────────────────────────────────────────────────

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 4, 16, MediaQuery.of(context).padding.bottom + 90),
      child: Row(
        children: [
          // Reset button
          GestureDetector(
            onTap: _reset,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(Icons.refresh_rounded,
                  color: Colors.white.withOpacity(0.4), size: 22),
            ),
          ),
          const SizedBox(width: 12),

          // Start / Stop button
          Expanded(
            child: GestureDetector(
              onTap: _toggleRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 52,
                decoration: BoxDecoration(
                  color: _isRecording
                      ? const Color(0xFFFF6B6B)
                      : _accentColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording
                              ? const Color(0xFFFF6B6B)
                              : _accentColor)
                          .withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isRecording
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        color: const Color(0xFF0A0A0F),
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isRecording ? 'Stop' : 'Start recording',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0A0A0F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Graph Painter ────────────────────────────────────────────────────────────

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
    final hPad = 16.0;
    final vPad = 24.0;
    final chartW = w - hPad * 2;
    final chartH = h - vPad * 2;

    // ── Grid lines ───────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = vPad + chartH * (1 - i / 4);
      canvas.drawLine(
          Offset(hPad, y), Offset(w - hPad, y), gridPaint);

      // Y-axis label
      final label = (yMax * i / 4).toStringAsFixed(0);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
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
      final peakPaint = Paint()
        ..color = const Color(0xFFFF6B6B).withOpacity(0.4)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
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
      canvas.drawPath(dashPath, peakPaint);
    }

    // ── Line path ─────────────────────────────────────────────────────────────
    final xStep = chartW / (maxPoints - 1);
    final startX = hPad + (maxPoints - data.length) * xStep;

    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withOpacity(0.25),
          accentColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(hPad, vPad, chartW, chartH))
      ..style = PaintingStyle.fill;

    final linePath = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = startX + i * xStep;
      final y = vPad + chartH * (1 - data[i] / yMax);
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, h - vPad);
        fillPath.lineTo(x, y);
      } else {
        // Smooth cubic bezier
        final prevX = startX + (i - 1) * xStep;
        final prevY = vPad + chartH * (1 - data[i - 1] / yMax);
        final cpX = (prevX + x) / 2;
        linePath.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    // Close fill path
    final lastX = startX + (data.length - 1) * xStep;
    fillPath.lineTo(lastX, h - vPad);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    // ── Live dot at the head of the line ──────────────────────────────────────
    if (isRecording && data.isNotEmpty) {
      final dotX = lastX;
      final dotY = vPad + chartH * (1 - data.last / yMax);
      canvas.drawCircle(
        Offset(dotX, dotY),
        4,
        Paint()..color = accentColor,
      );
      canvas.drawCircle(
        Offset(dotX, dotY),
        7,
        Paint()
          ..color = accentColor.withOpacity(0.25)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.data != data ||
      old.peakValue != peakValue ||
      old.isRecording != isRecording;
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: color.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withOpacity(0.55),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing recording dot ────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.active});
  final bool active;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingDot old) {
    super.didUpdateWidget(old);
    widget.active ? _pulse.repeat(reverse: true) : _pulse.stop();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.active
              ? const Color(0xFFFF6B6B)
                  .withValues(alpha: 0.6 + 0.4 * _pulse.value)
              : Colors.white24,
        ),
      ),
    );
  }
}