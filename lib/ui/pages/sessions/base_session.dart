import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifter/features/workouts/workout_provider.dart';
import 'package:lifter/features/workouts/graph.dart';

// ─── BaseSessionPage ──────────────────────────────────────────────────────────
// The shared scaffold for every workout session.
// Provides: header, graph area, overlay slot, and stop/reset controls.
//
// Each concrete session page passes its own [overlay] widget which appears
// on top of the graph (e.g. a timer, a rep counter, a phase indicator).
//
// Usage:
//   BaseSessionPage(
//     title: 'Peak Load',
//     accentColor: Color(0xFFFF6B6B),
//     controller: _graphController,
//     isRecording: _isRecording,
//     showPeakLine: true,
//     overlay: MyTimerWidget(...),
//     onToggle: _toggleRecording,
//     onReset: _reset,
//   )

class BaseSessionPage extends ConsumerWidget {
  const BaseSessionPage({
    super.key,
    required this.title,
    required this.accentColor,
    required this.controller,
    required this.isRecording,
    required this.onToggle,
    required this.onReset,
    this.showPeakLine = true,
    this.overlay,
  });

  final String title;
  final Color accentColor;
  final LiveGraphController controller;
  final bool isRecording;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final bool showPeakLine;

  /// Optional widget rendered over the graph (timer, rep counter, etc.)
  final Widget? overlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildGraphArea()),
          _buildStatsRow(),
          _buildControls(context, ref),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 20, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios_rounded,
                size: 20, color: Colors.white.withOpacity(0.6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: Color(0xFFF0F0F0),
              ),
            ),
          ),
          // Recording badge
          _RecordingBadge(isRecording: isRecording),
        ],
      ),
    );
  }

  // ── Graph area with overlay ──────────────────────────────────────────────────

  Widget _buildGraphArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Stack(
        children: [
          // Graph fills the space
          Positioned.fill(
            child: LiveGraph(
              controller: controller,
              accentColor: accentColor,
              showPeakLine: showPeakLine,
              isRecording: isRecording,
            ),
          ),
          // Overlay sits on top (top-right corner by default)
          if (overlay != null)
            Positioned(
              top: 12,
              right: 12,
              child: overlay!,
            ),
        ],
      ),
    );
  }

  // ── Stats row ────────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: _StatChip(
                label: 'Current',
                value: controller.currentValue.toStringAsFixed(1),
                unit: 'kg',
                color: accentColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatChip(
                label: 'Peak',
                value: controller.peakValue.toStringAsFixed(1),
                unit: 'kg',
                color: const Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(width: 10),
            // Expanded(
            //   child: _StatChip(
            //     label: 'Samples',
            //     value: controller.,
            //     unit: '',
            //     color: const Color(0xFFB47FFF),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // ── Controls ─────────────────────────────────────────────────────────────────

  Widget _buildControls(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 24),
      child: Row(
        children: [
          // Reset
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onReset();
            },
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

          // Start / Stop
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onToggle();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 52,
                decoration: BoxDecoration(
                  color: isRecording
                      ? const Color(0xFFFF6B6B)
                      : accentColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (isRecording
                              ? const Color(0xFFFF6B6B)
                              : accentColor)
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
                        isRecording
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        color: const Color(0xFF0A0A0F),
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRecording ? 'Stop' : 'Start',
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

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _RecordingBadge extends StatefulWidget {
  const _RecordingBadge({required this.isRecording});
  final bool isRecording;

  @override
  State<_RecordingBadge> createState() => _RecordingBadgeState();
}

class _RecordingBadgeState extends State<_RecordingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isRecording) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_RecordingBadge old) {
    super.didUpdateWidget(old);
    widget.isRecording ? _pulse.repeat(reverse: true) : _pulse.stop();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.isRecording
            ? const Color(0xFFFF6B6B).withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isRecording
              ? const Color(0xFFFF6B6B).withOpacity(0.4)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isRecording
                    ? const Color(0xFFFF6B6B)
                        .withOpacity(0.6 + 0.4 * _pulse.value)
                    : Colors.white24,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.isRecording ? 'REC' : 'IDLE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: widget.isRecording
                  ? const Color(0xFFFF6B6B)
                  : Colors.white30,
            ),
          ),
        ],
      ),
    );
  }
}

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
