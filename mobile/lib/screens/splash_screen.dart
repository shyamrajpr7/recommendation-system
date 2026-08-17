import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _checkAuthAndRoute();
  }

  Future<void> _checkAuthAndRoute() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    // TODO: re-enable real auth check
    // final authService = ref.read(authServiceProvider);
    // final isLoggedIn = await authService.isLoggedIn;
    // if (!mounted) return;
    // if (isLoggedIn) {
    //   context.go('/home');
    // } else {
    //   context.go('/login');
    // }
    context.go('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent1.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.movie_filter_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'CineRead',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI-powered cinema booking',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.accent1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
