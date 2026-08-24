import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/app_dimens.dart';
import '../services/settings_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium)
            .animate().fadeIn(duration: 400.ms)
            .slideX(begin: -0.05, end: 0),
        const SizedBox(height: AppSpacing.xxl),
        // Profile card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.accent2.withValues(alpha: 0.2),
              child: const Icon(Icons.person_rounded, size: 30, color: AppColors.accent2),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alex Johnson', style: Theme.of(context).textTheme.titleMedium),
                  Text('Signed in', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.muted),
          ]),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms)
            .slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms),
        const SizedBox(height: AppSpacing.xxl),
        // Section: Preferences
        _sectionHeader('Preferences', 150),
        const SizedBox(height: AppSpacing.md),
        // Grouped preferences card
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            children: [
              _buildToggleTile(
                icon: Icons.notifications_rounded,
                title: 'Push Notifications',
                subtitle: 'Get booking & recommendation alerts',
                value: ref.watch(notificationsProvider),
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  ref.read(notificationsProvider.notifier).toggle(v);
                },
              ),
              _divider(),
              _buildThemeTile(ref, isDark),
              _divider(),
              _buildToggleTile(
                icon: Icons.play_circle_outline_rounded,
                title: 'Auto-play Trailers',
                subtitle: 'Play trailers automatically',
                value: ref.watch(autoPlayTrailersProvider),
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  ref.read(autoPlayTrailersProvider.notifier).toggle(v);
                },
              ),
              _divider(),
              _buildToggleTile(
                icon: Icons.location_on_outlined,
                title: 'Location Services',
                subtitle: 'Find nearby theaters',
                value: ref.watch(locationServicesProvider),
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  ref.read(locationServicesProvider.notifier).toggle(v);
                },
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.05, end: 0, delay: 200.ms, duration: 400.ms),
        const SizedBox(height: AppSpacing.xxl),
        // Section: About
        _sectionHeader('About', 350),
        const SizedBox(height: AppSpacing.md),
        // Grouped about card
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            children: [
              _buildInfoTile(Icons.info_outline, 'About CineRead', 'AI-powered cinema booking'),
              _divider(),
              _buildInfoTile(Icons.code_rounded, 'API Status', 'Backend: localhost:8000'),
              _divider(),
              _buildInfoTile(Icons.phone_android_rounded, 'Platform', 'macOS desktop'),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
        const SizedBox(height: AppSpacing.xxxl),
        // Logout
        SizedBox(
          width: double.infinity,
          height: AppDimens.buttonHeight,
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.go('/login');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              ),
            ),
            child: const Text('Log out'),
          ),
        ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
        const SizedBox(height: AppSpacing.xl),
        // Version footer
        Center(
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.movie_filter_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text('CineRead v1.0.1', style: TextStyle(color: AppColors.muted2, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('AI-Powered Cinema Booking', style: TextStyle(color: AppColors.muted2, fontSize: 10)),
            ],
          ),
        ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _sectionHeader(String label, int delayMs) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
            letterSpacing: 0.05,
          ),
        ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: delayMs), duration: 400.ms);
  }

  Widget _divider() {
    return Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.borderSoft);
  }

  Widget _buildThemeTile(WidgetRef ref, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Icon(Icons.dark_mode_rounded, size: 20, color: AppColors.accent1),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(isDark ? 'Dark mode' : 'Light mode', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _themeChip(Icons.dark_mode_rounded, 'Dark', isDark, () {
                  HapticFeedback.lightImpact();
                  ref.read(darkModeProvider.notifier).toggle(true);
                }),
                _themeChip(Icons.light_mode_rounded, 'Light', !isDark, () {
                  HapticFeedback.lightImpact();
                  ref.read(darkModeProvider.notifier).toggle(false);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeChip(IconData icon, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd - 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : AppColors.muted),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
              color: selected ? Colors.white : AppColors.muted,
              fontSize: 11, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Icon(icon, size: 20, color: AppColors.accent1),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Switch(
              key: ValueKey(value),
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.accent1,
              activeTrackColor: AppColors.accent1.withValues(alpha: 0.3),
              inactiveTrackColor: AppColors.surface3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(children: [
        Icon(icon, size: 22, color: AppColors.accent1),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(sub, style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }
}
