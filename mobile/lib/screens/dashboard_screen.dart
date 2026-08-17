import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';

class DashboardShell extends StatelessWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/search')) return 1;
    if (path.startsWith('/chat')) return 2;
    if (path.startsWith('/bookings')) return 3;
    if (path.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: child),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderSoft)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBtn(icon: Icons.movie_filter_rounded, label: 'Movies', active: idx == 0, onTap: () => context.go('/home')),
                _NavBtn(icon: Icons.search_rounded, label: 'Search', active: idx == 1, onTap: () => context.go('/search')),
                _NavBtn(icon: Icons.chat_bubble_outline_rounded, label: 'Chat', active: idx == 2, onTap: () => context.go('/chat')),
                _NavBtn(icon: Icons.confirmation_number_outlined, label: 'Tickets', active: idx == 3, onTap: () => context.go('/bookings')),
                _NavBtn(icon: Icons.settings_rounded, label: 'Settings', active: idx == 4, onTap: () => context.go('/settings')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.label, required this.active, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent1 : AppColors.muted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.accent1.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
