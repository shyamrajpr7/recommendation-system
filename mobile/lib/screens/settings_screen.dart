import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/app_dimens.dart';
import '../services/settings_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _locationEnabled = true;

  @override
  Widget build(BuildContext context) {
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
                  Text('Guest User', style: Theme.of(context).textTheme.titleMedium),
                  Text('Development mode', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.muted),
          ]),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms)
            .slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms),
        const SizedBox(height: AppSpacing.xxl),
        // Section: Preferences
        Text(
          'Preferences',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildToggleTile(
          icon: Icons.notifications_rounded,
          title: 'Push Notifications',
          subtitle: 'Get booking & recommendation alerts',
          value: ref.watch(notificationsProvider),
          onChanged: (v) {
            HapticFeedback.lightImpact();
            ref.read(notificationsProvider.notifier).toggle(v);
          },
          delayMs: 200,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildToggleTile(
          icon: Icons.dark_mode_rounded,
          title: 'Dark Mode',
          subtitle: 'Use dark theme',
          value: ref.watch(darkModeProvider),
          onChanged: (v) {
            HapticFeedback.lightImpact();
            ref.read(darkModeProvider.notifier).toggle(v);
          },
          delayMs: 250,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildToggleTile(
          icon: Icons.play_circle_outline_rounded,
          title: 'Auto-play Trailers',
          subtitle: 'Play trailers automatically',
          value: ref.watch(autoPlayTrailersProvider),
          onChanged: (v) {
            HapticFeedback.lightImpact();
            ref.read(autoPlayTrailersProvider.notifier).toggle(v);
          },
          delayMs: 300,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildToggleTile(
          icon: Icons.location_on_outlined,
          title: 'Location Services',
          subtitle: 'Find nearby theaters',
          value: _locationEnabled,
          onChanged: (v) {
            HapticFeedback.lightImpact();
            setState(() => _locationEnabled = v);
          },
          delayMs: 350,
        ),
        const SizedBox(height: AppSpacing.xxl),
        // Section: About
        Text(
          'About',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildInfoTile(Icons.info_outline, 'About CineRead', 'AI-powered cinema booking'),
        const SizedBox(height: AppSpacing.md),
        _buildInfoTile(Icons.code_rounded, 'API Status', 'Backend: localhost:8000'),
        const SizedBox(height: AppSpacing.md),
        _buildInfoTile(Icons.phone_android_rounded, 'Platform', 'macOS desktop'),
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
      ],
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required int delayMs,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.borderSoft),
      ),
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
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delayMs), duration: 400.ms)
        .slideX(begin: 0.05, end: 0, delay: Duration(milliseconds: delayMs), duration: 400.ms);
  }

  Widget _buildInfoTile(IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.borderSoft),
      ),
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
