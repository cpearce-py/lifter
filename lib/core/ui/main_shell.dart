import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lifter/core/ui/home_page.dart';
import 'package:lifter/features/history/ui/history_page.dart';
import 'package:lifter/features/telemetry/ui/pages/progression_page.dart';
import 'package:lifter/features/user/ui/profile_page.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_selection_sheet.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

// ─── Drop-in Bottom Nav Shell ─────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
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
        page: const HomePage(),
      ),
      // The Workout destination is flagged as an "Action"
      _NavDestination(
        label: 'Workout',
        icon: Icons.fitness_center_outlined,
        activeIcon: Icons.fitness_center_rounded,
        isAction: true,
        page: const SizedBox(), // Won't be rendered in the stack
      ),
      _NavDestination(
        label: 'History',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        page: const ProgressionPage(),
      ),
      _NavDestination(
        label: 'Profile',
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        page: const ProfilePage(),
      ),
    ];
  }

  @override
  void dispose() {
    _tabNotifier.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (_destinations[index].isAction) {
      HapticFeedback.lightImpact();
      _showWorkoutSheet(context);
      return; // Stop here so the active tab DOES NOT change
    }
    _tabNotifier.value = index;
  }

  // ─── The Slide-up Window ───────────────────────────────────────────────────
  void _showWorkoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: context.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 24),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: context.textPrimary.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "SELECT WORKOUT",
                style: context.body.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Center(
                  child: WorkoutSelectionSheet()
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter out the action page from the IndexedStack so indices align
    final pages = _destinations.where((d) => !d.isAction).map((d) => d.page).toList();

    // Calculate the actual index for IndexedStack by ignoring the action button
    int stackIndex = _currentIndex;
    if (_currentIndex > _destinations.indexWhere((d) => d.isAction)) {
      stackIndex -= 1;
    }

    return Scaffold(
      backgroundColor: context.background,
      body: IndexedStack(
        index: stackIndex,
        children: pages,
      ),
      bottomNavigationBar: _FitBottomNav(
        destinations: _destinations,
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
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
        color: context.cardBackground,
        border: Border(
          top: BorderSide(color: context.cardBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDark 
                ? Colors.black.withValues(alpha: 0.6) 
                : Colors.black.withValues(alpha: 0.05),
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

// ─── Nav Button Router ────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.destination,
    required this.isActive,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.repeaterAccent;
 
    if (destination.isAction) {
      return _ActionTabWidget(
        destination: destination,
        accent: accent,
        onTap: onTap,
      );
    }

    return _StandardTabWidget(
      destination: destination,
      isActive: isActive,
      accent: accent,
      onTap: onTap,
    );
  }
}

// ─── Action Tab Widget (Stateless) ────────────────────────────────────────────

class _ActionTabWidget extends StatelessWidget {
  const _ActionTabWidget({
    required this.destination,
    required this.accent,
    required this.onTap,
  });

  final _NavDestination destination;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              destination.icon,
              size: 28,
              color: context.cardBackground,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Standard Tab Widget (Stateful for animations) ────────────────────────────

class _StandardTabWidget extends StatefulWidget {
  const _StandardTabWidget({
    required this.destination,
    required this.isActive,
    required this.accent,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool isActive;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_StandardTabWidget> createState() => _StandardTabWidgetState();
}

class _StandardTabWidgetState extends State<_StandardTabWidget>
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
  void didUpdateWidget(_StandardTabWidget old) {
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: widget.isActive ? 48 : 0,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.accent.withOpacity(0.12),
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
                        context.textMuted,
                        widget.accent,
                        _glowAnim.value,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: 0.5,
                  color: widget.isActive
                      ? widget.accent
                      : context.textMuted,
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
    this.isAction = false,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;
  final bool isAction;
}
