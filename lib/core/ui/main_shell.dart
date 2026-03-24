import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lifter/ui/pages/graph_page.dart';
import 'home_page.dart';
import 'package:lifter/features/workouts/workout_page.dart';

// ─── Drop-in Bottom Nav Shell ─────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Shared notifier — any page can write to this to switch the active tab.
  final _tabNotifier = ValueNotifier<int>(0);
  int _currentIndex = 0;

  late final List<_NavDestination> _destinations;

  @override
  void initState() {
    super.initState();

    _tabNotifier.addListener(() {
      if (_tabNotifier.value != _currentIndex) {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = _tabNotifier.value);
      }
    });

    _destinations = [
      _NavDestination(
        label: 'Home',
        icon: Icons.home_rounded,
        activeIcon: Icons.home_rounded,
        page: HomePage(),
      ),
      _NavDestination(
        label: 'Workout',
        icon: Icons.fitness_center_outlined,
        activeIcon: Icons.fitness_center_rounded,
        page: WorkoutNavigator(),
      ),
      _NavDestination(
        label: 'Graph',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        page: WorkoutLiveGraphDebugPage(),
      ),
      _NavDestination(
        label: 'Profile',
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        page: _PagePlaceholder(label: "Profile", icon: Icons.abc),
      ),
    ];
  }

  @override
  void dispose() {
    _tabNotifier.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    _tabNotifier.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: IndexedStack(
        index: _currentIndex,
        children: [for (final d in _destinations) d.page],
      ),
      bottomNavigationBar: _FitBottomNav(
        destinations: _destinations,
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

class WorkoutNavigator extends StatelessWidget {
  const WorkoutNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => const WorkoutPage()),
    );
  }
}

// ─── Bottom Nav Widget ────────────────────────────────────────────────────────

class _FitBottomNav extends StatelessWidget {
  const _FitBottomNav({
    required this.destinations,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        border: const Border(
          top: BorderSide(color: Color(0xFF1E1E2A), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(destinations.length, (index) {
              final isActive = index == currentIndex;
              return Expanded(
                child: _NavButton(
                  destination: destinations[index],
                  isActive: isActive,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Individual Nav Button ────────────────────────────────────────────────────

class _NavButton extends StatefulWidget {
  const _NavButton({
    required this.destination,
    required this.isActive,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.isActive ? 1.0 : 0.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _glowAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(_NavButton old) {
    super.didUpdateWidget(old);
    if (widget.isActive != old.isActive) {
      widget.isActive ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE8FF47);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with glow pill behind it
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow pill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: widget.isActive ? 48 : 0,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Icon(
                      widget.isActive
                          ? widget.destination.activeIcon
                          : widget.destination.icon,
                      size: 22,
                      color: Color.lerp(
                        Colors.white.withOpacity(0.35),
                        accent,
                        _glowAnim.value,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      widget.isActive ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: 0.5,
                  color: widget.isActive
                      ? accent
                      : Colors.white.withOpacity(0.35),
                ),
                child: Text(widget.destination.label),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;
}

// ─── Placeholder pages (swap with real screens) ───────────────────────────────

class _PagePlaceholder extends StatelessWidget {
  const _PagePlaceholder({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.white10),
            const SizedBox(height: 16),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: Colors.white12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
