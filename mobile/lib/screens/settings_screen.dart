import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xxl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.accent2.withValues(alpha: 0.2),
              child: const Icon(Icons.person_rounded, size: 30, color: AppColors.accent2),
            ),
            const SizedBox(width: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guest User', style: Theme.of(context).textTheme.titleMedium),
                Text('Development mode', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _tile(Icons.info_outline, 'About CineRead', 'AI-powered cinema booking'),
        const SizedBox(height: AppSpacing.md),
        _tile(Icons.code, 'API Status', 'Backend: localhost:8000'),
        const SizedBox(height: AppSpacing.md),
        _tile(Icons.phone_android, 'Platform', 'macOS desktop'),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Log out'),
          ),
        ),
      ],
    );
  }

  Widget _tile(IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(children: [
        Icon(icon, size: 22, color: AppColors.accent1),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(sub, style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        )),
      ]),
    );
  }
}
