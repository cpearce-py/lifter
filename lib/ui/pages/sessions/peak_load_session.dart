import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/graph.dart';
import 'base_session.dart';

// ─── PeakLoadSessionPage ──────────────────────────────────────────────────────
// Graph session for the Peak Load workout.
// Overlay: a hold-duration countdown timer.
// Each attempt auto-stops recording when the hold duration elapses.

class PeakLoadSessionPage extends StatefulWidget {
  const PeakLoadSessionPage({
    super.key,
    required this.attempts,
    required this.restSeconds,
    required this.holdSeconds,
    required this.beepCountdown,
  });

  final int attempts;
  final int restSeconds;
  final int holdSeconds;
  final bool beepCountdown;

  @override
  State<PeakLoadSessionPage> createState() => _PeakLoadSessionPageState();
}

class _PeakLoadSessionPageState extends State<PeakLoadSessionPage> {
  static const _accentColor = Color(0xFFFF6B6B);

  late final LiveGraphController _graph;

  bool _isRecording = false;
  int _currentAttempt = 1;
  int _secondsLeft = 0;

  Timer? _holdTimer;
  Timer? _mockTimer;
  double _mockPhase = 0;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _graph = LiveGraphController(yMax: 100);
    _secondsLeft = widget.holdSeconds;
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _mockTimer?.cancel();
    _graph.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isRecording) {
      _stopAttempt();
    } else {
      _startAttempt();
    }
  }

  void _startAttempt() {
    setState(() {
      _isRecording = true;
      _secondsLeft = widget.holdSeconds;
    });

    // ── Swap for real BLE stream ───────────────────────────────────────────
    _mockTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _mockPhase += 0.06;
      final v = (50 + 35 * sin(_mockPhase) + (_rng.nextDouble() - 0.5) * 8)
          .clamp(0.0, 100.0);
      _graph.addSample(v);
    });

    // Count down the hold duration
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _stopAttempt();
    });
  }

  void _stopAttempt() {
    _holdTimer?.cancel();
    _mockTimer?.cancel();
    setState(() {
      _isRecording = false;
      if (_currentAttempt < widget.attempts) _currentAttempt++;
    });
  }

  void _reset() {
    _holdTimer?.cancel();
    _mockTimer?.cancel();
    _graph.reset(resetPeak: true);
    setState(() {
      _isRecording = false;
      _currentAttempt = 1;
      _secondsLeft = widget.holdSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseSessionPage(
      title: 'Peak Load',
      accentColor: _accentColor,
      controller: _graph,
      isRecording: _isRecording,
      showPeakLine: true,
      onToggle: _toggle,
      onReset: _reset,
      overlay: _HoldTimerOverlay(
        secondsLeft: _isRecording ? _secondsLeft : widget.holdSeconds,
        totalSeconds: widget.holdSeconds,
        currentAttempt: _currentAttempt,
        totalAttempts: widget.attempts,
        accentColor: _accentColor,
        isActive: _isRecording,
      ),
    );
  }
}

// ─── Hold Timer Overlay ───────────────────────────────────────────────────────

class _HoldTimerOverlay extends StatelessWidget {
  const _HoldTimerOverlay({
    required this.secondsLeft,
    required this.totalSeconds,
    required this.currentAttempt,
    required this.totalAttempts,
    required this.accentColor,
    required this.isActive,
  });

  final int secondsLeft;
  final int totalSeconds;
  final int currentAttempt;
  final int totalAttempts;
  final Color accentColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0 ? secondsLeft / totalSeconds : 1.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attempt counter
          Text(
            'ATTEMPT $currentAttempt / $totalAttempts',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: accentColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),

          // Circular countdown
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withOpacity(0.07),
                  valueColor: AlwaysStoppedAnimation(
                    isActive ? accentColor : accentColor.withOpacity(0.3),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$secondsLeft',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isActive ? accentColor : Colors.white38,
                        height: 1,
                      ),
                    ),
                    Text(
                      's',
                      style: TextStyle(
                        fontSize: 10,
                        color: accentColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}