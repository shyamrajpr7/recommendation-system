import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_animations.dart';

class DashboardShell extends StatelessWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/explore')) return 1;
    if (path.startsWith('/favorites')) return 2;
    if (path.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: child),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            border: Border.all(color: AppColors.borderSoft, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBtn(
                icon: Icons.movie_filter_rounded,
                label: 'Home',
                active: idx == 0,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go('/home');
                },
              ),
              _NavBtn(
                icon: Icons.explore_rounded,
                label: 'Explore',
                active: idx == 1,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go('/explore');
                },
              ),
              _NavBtn(
                icon: Icons.favorite_rounded,
                label: 'Favorites',
                active: idx == 2,
                badgeCount: 3,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go('/favorites');
                },
              ),
              _NavBtn(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: idx == 3,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go('/profile');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int? badgeCount;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badgeCount,
  });

  @override
  State<_NavBtn> createState() => _NavBtnState();
}

class _NavBtnState extends State<_NavBtn> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(_NavBtn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _bounceController.forward().then((_) => _bounceController.reverse());
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? AppColors.accent1 : AppColors.muted;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: AppAnimations.normal,
                  curve: AppAnimations.defaultCurve,
                  width: widget.active ? 40 : 0,
                  height: widget.active ? 40 : 0,
                  decoration: BoxDecoration(
                    color: widget.active
                        ? AppColors.accent1.withValues(alpha: 0.15)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: widget.active ? _bounceAnimation.value : 1.0,
                          child: child,
                        );
                      },
                      child: Icon(widget.icon, size: 22, color: color),
                    ),
                  ),
                ),
                if (widget.badgeCount != null && widget.badgeCount! > 0)
                  Positioned(
                    right: 2,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: Text(
                        '${widget.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppAnimations.normal,
              style: TextStyle(
                fontSize: 10,
                fontWeight: widget.active ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}
