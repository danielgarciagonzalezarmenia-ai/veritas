import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/scan_setup_sheet.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.state});

  final AppState state;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  void _go(int index) {
    setState(() => _index = index);
  }

  Future<void> _scan() async {
    final subject = await showScanSetup(context, widget.state);
    if (subject == null || !mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ScanScreen(state: widget.state, subject: subject),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        return Scaffold(
          body: Stack(
            children: [
              IndexedStack(
                index: _index,
                children: [
                  HomeScreen(
                    state: widget.state,
                    onOpenSettings: () => _go(3),
                    onOpenHistory: () => _go(1),
                  ),
                  HistoryScreen(state: widget.state, onOpenScan: _scan),
                  InsightsScreen(state: widget.state),
                  SettingsScreen(state: widget.state),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom - 4
                    : 12,
                child: _BottomNav(
                  index: _index,
                  onSelect: _go,
                  onScan: _scan,
                  surface: c.surfaceAlt,
                  border: c.line,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.onSelect,
    required this.onScan,
    required this.surface,
    required this.border,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;
  final Color surface;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 74,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(color: surface.withValues(alpha: 0.94)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Inicio',
                  active: index == 0,
                  onTap: () => onSelect(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.history_rounded,
                  label: 'Historial',
                  active: index == 1,
                  onTap: () => onSelect(1),
                ),
              ),
              Expanded(
                child: Center(
                  child: Pressable(
                    onTap: onScan,
                    scale: 0.92,
                    borderRadius: 30,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [c.orangeSoft, c.orange],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: c.orange.withValues(alpha: 0.38),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Icon(
                        Icons.center_focus_strong_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.insights_rounded,
                  label: 'Progreso',
                  active: index == 2,
                  onTap: () => onSelect(2),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.settings_outlined,
                  label: 'Ajustes',
                  active: index == 3,
                  onTap: () => onSelect(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = active ? c.text : c.muted;
    return Pressable(
      onTap: onTap,
      borderRadius: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 21, color: color),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.1,
              color: color,
            ),
            child: Text(label),
          ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 14 : 0,
            height: 2.5,
            decoration: BoxDecoration(
              color: c.orange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
