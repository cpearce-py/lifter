import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/scale_provider.dart';
import 'package:lifter/features/workouts/graph.dart';

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
  bool isActive = true;

  void _toggleGraph() {
    debugPrint("Changing isActive");
    setState(() {
      isActive = !isActive;
    });
  }

  @override
  void dispose() {
    _graphController.dispose();
    _packetCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(weightStreamProvider, (_, next) {
      next.whenData((reading) {
        if (!isActive) return;
        _graphController.addSample(reading.weightKg);
        _packetCount.value++;
      });
    });

    final latestWeight = ref.watch(
      weightStreamProvider.select((s) => s.whenOrNull(data: (r) => r)),
    );

    final isReceiving = latestWeight != null;

    return Scaffold(
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
            _DebugCard(
              children: [
                _DebugRow('Signal', isReceiving ? '🟢 Receiving' : '🟡 Scanning'),
                _DebugRow(
                  'Weight',
                  latestWeight == null
                      ? '—'
                      : '${latestWeight.weightKg.toStringAsFixed(2)} kg'
                        '  ${latestWeight.isStable ? '✅ stable' : '⏳ settling'}',
                ),
                _DebugRow(
                  'Peak',
                  '${_graphController.peakValue.toStringAsFixed(2)} kg',
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
                    onTap: () => _graphController.reset(resetPeak: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DebugButton(
                    label: isActive ? 'Toggle Active': "Resume Graph",
                    icon: Icons.flag_rounded,
                    onTap: () => _toggleGraph(),
                  ),
                ),
              ],
            ),
          ],
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
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.4),
                  fontWeight: FontWeight.w600)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  const _DebugButton(
      {required this.label, required this.icon, required this.onTap});
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
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}
