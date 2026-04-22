import 'package:flutter/material.dart';

// Defines the signature for the function we will hand back to your UI
typedef NextWaveBuilderItem = Widget Function(Widget child);

class WaveAnimator extends StatefulWidget {
  final Widget Function(BuildContext context, NextWaveBuilderItem waveItem) builder;
  final Duration duration;
  final Duration delay;
  final Offset beginOffset;

  const WaveAnimator({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 800),
    this.delay = const Duration(milliseconds: 50),
    this.beginOffset = const Offset(0.2, 0.0), // Defaults to sliding from the right
  });

  @override
  State<WaveAnimator> createState() => _WaveAnimatorState();
}

class _WaveAnimatorState extends State<WaveAnimator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    
    // Add a tiny delay so page transitions finish before the wave kicks off
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildWaveItem(int index, Widget child) {
    final start = (index * 0.08).clamp(0.0, 1.0);
    final end = (start + 0.4).clamp(0.0, 1.0);

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: widget.beginOffset,
        end: Offset.zero,
      ).animate(curve),
      child: FadeTransition(
        opacity: curve,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int currentIndex = 0;
    
    Widget nextWave(Widget child) {
      final widget = _buildWaveItem(currentIndex, child);
      currentIndex++;
      return widget;
      }
    // Hand the context and the helper function back to whatever UI is using this widget
    return widget.builder(context, nextWave);
  }
}
