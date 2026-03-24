import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/scale_provider.dart';
import 'package:lifter/features/bluetooth/ble_service.dart';
import 'package:lifter/features/bluetooth/ui/widgets.dart';
import 'package:lifter/features/workouts/graph.dart';
import 'package:visibility_detector/visibility_detector.dart';

class WorkoutLiveGraphDebugPage extends ConsumerStatefulWidget {
  const WorkoutLiveGraphDebugPage({super.key});

  @override
  ConsumerState<WorkoutLiveGraphDebugPage> createState() =>
      _WorkoutLiveGraphDebugPageState();
}

class _WorkoutLiveGraphDebugPageState
    extends ConsumerState<WorkoutLiveGraphDebugPage> {
  static const _accentColor = Color(0xFF47C8FF);

  final _graphController = LiveGraphController(yMax: 10.0);
  final _packetCount = ValueNotifier<int>(0);
  final _latestWeight = ValueNotifier<WeightReading?>(null);
  bool isActive = true;
  bool _isVisible = true;

  void _toggleGraph() {
    setState(() {
      isActive = !isActive;
    });
  }

  @override
  void dispose() {
    _graphController.dispose();
    _packetCount.dispose();
    _latestWeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(weightStreamProvider, (_, next) {
      if (!_isVisible || !isActive) return;
      next.whenData((reading) {
        _graphController.addSample(reading.weightKg);
        _packetCount.value++;
        _latestWeight.value = reading;
      });
    });

    return VisibilityDetector(
      key: const Key('debug-page-visibility'),
      onVisibilityChanged: (info) {
        _isVisible = info.visibleFraction > 0;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0A0F),
          foregroundColor: Colors.white,
          title: const Text('BLE Debug'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConnectBluetoothButton(),
              _DebugCard(
                children: [
                  // 4. Wrap the text widgets in ValueListenableBuilders
                  // This means ONLY these tiny text widgets rebuild when data arrives.
                  ValueListenableBuilder<WeightReading?>(
                    valueListenable: _latestWeight,
                    builder: (context, weight, _) {
                      final isReceiving = weight != null;
                      return Column(
                        children: [
                          _DebugRow(
                            'Signal',
                            isReceiving ? '🟢 Receiving' : '🟡 Scanning',
                          ),
                          _DebugRow(
                            'Weight',
                            weight == null
                                ? '—'
                                : '${weight.weightKg.toStringAsFixed(2)} kg'
                                      '  ${weight.isStable ? '✅ stable' : '⏳ settling'}',
                          ),
                        ],
                      );
                    },
                  ),

                  // For the peak, we can just use an AnimatedBuilder on the controller
                  AnimatedBuilder(
                    animation: _graphController,
                    builder: (context, _) => _DebugRow(
                      'Peak',
                      '${_graphController.peakValue.toStringAsFixed(2)} kg',
                    ),
                  ),

                  ValueListenableBuilder<int>(
                    valueListenable: _packetCount,
                    builder: (_, count, _) => _DebugRow("Packets", '$count'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LiveGraph(
                  controller: _graphController,
                  accentColor: _accentColor,
                  showPeakLine: true,
                  isActive: isActive,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DebugButton(
                      label: 'Reset Graph',
                      icon: Icons.refresh_rounded,
                      onTap: () {
                        _graphController.reset(resetPeak: false);
                        _packetCount.value = 0; // Reset packets too!
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DebugButton(
                      label: isActive ? 'Pause' : 'Resume',
                      icon: isActive
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      onTap: _toggleGraph,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Small debug UI helpers ───────────────────────────────────────────────────

class _DebugCard extends StatelessWidget {
  const _DebugCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(children: children),
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.4),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  const _DebugButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white.withOpacity(0.5)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
