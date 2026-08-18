import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/app_dimens.dart';
import '../theme/app_animations.dart';

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Discover Movies',
      description: 'AI-powered recommendations tailored to your taste. Discover your next favorite film in seconds.',
      icon: Icons.explore_rounded,
      accentColor: Color(0xFF38BDF8),
    ),
    OnboardingPage(
      title: 'Smart Booking',
      description: 'Choose seats, compare showtimes, and book tickets seamlessly with our intelligent assistant.',
      icon: Icons.confirmation_number_rounded,
      accentColor: Color(0xFF818CF8),
    ),
    OnboardingPage(
      title: 'Your Cinema Hub',
      description: 'Track bookings, manage favorites, and get personalized insights — all in one place.',
      icon: Icons.dashboard_rounded,
      accentColor: Color(0xFFA78BFA),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppAnimations.pageTransition,
        curve: AppAnimations.defaultCurve,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    context.go('/login');
  }

  void _skip() {
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _buildPage(_pages[index], index),
              ),
            ),
            // Bottom section
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.xxxl),
              child: Column(
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: AppAnimations.normal,
                        curve: AppAnimations.defaultCurve,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? _pages[_currentPage].accentColor
                              : AppColors.surface3,
                          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  // Next / Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: AppDimens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ).animate(key: ValueKey(_currentPage))
                        .fadeIn(duration: 200.ms)
                        .slideX(begin: 0.05, end: 0, duration: 200.ms),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.accentColor.withValues(alpha: 0.1),
              border: Border.all(
                color: page.accentColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: page.accentColor,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 300.ms),
          const SizedBox(height: AppSpacing.xxxl + 8),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              height: 1.2,
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0, delay: 100.ms, duration: 400.ms),
          const SizedBox(height: AppSpacing.lg),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 400.ms),
        ],
      ),
    );
  }
}
